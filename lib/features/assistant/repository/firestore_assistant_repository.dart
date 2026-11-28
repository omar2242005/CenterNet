import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../auth/models/app_user.dart';
import '../../groups/models/group.dart';
import '../../payments/models/payment.dart';
import '../../sessions/models/session.dart';
import '../../students/models/student.dart';
import '../models/attendance.dart';
import '../models/pending_scan.dart';
import '../models/scan_setup.dart';
import '../rules/scan_validator.dart';
import 'assistant_repository.dart';

/// مزامنة حضور المساعد مع Firestore + قراءات شاشات المساعد.
///
/// persistence مفعّل في التطبيق، فنجاح `set` وحده معناه أن الكتابة دخلت
/// الكاش فقط. لا نعتبر المسحة متزامنة إلا بعد `Source.server` يؤكدها.
class FirestoreAssistantRepository implements AssistantRepository {
  FirestoreAssistantRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration serverConfirmationTimeout = Duration(seconds: 20);

  @override
  Future<void> writeAttendance(PendingScan scan) async {
    final centerId = scan.centerId;
    final status = scan.attendanceStatus;
    if (centerId == null || status == null) {
      throw const Failure.validation(
        'هذه مسحة قديمة ناقصة بيانات المزامنة. راجع إدارة السنتر.',
      );
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();

    final attendance = Attendance.create(
      centerId: centerId,
      sessionId: scan.sessionId,
      studentId: scan.studentId,
      status: switch (status) {
        PendingAttendanceStatus.present => AttendanceStatus.present,
        PendingAttendanceStatus.late => AttendanceStatus.lateArrival,
      },
      method: AttendanceMethod.qr,
      scannedAt: scan.scannedAt,
      recordedBy: uid,
      paymentStatus: scan.paymentStatus,
    );
    final ref = _db.doc(FirestorePaths.attendanceDoc(centerId, attendance.id));

    try {
      await ref.set(attendance.toCreateMap());
      await _confirmMatchingServerRecord(ref, attendance);
    } on Object catch (error) {
      final failure = ErrorMapper.map(error);

      // لو التطبيق مات بعد تأكيد الكتابة وقبل markSynced، المحاولة الجديدة
      // تُرفض كـ update. القراءة من السيرفر هي التي تثبت أنها نفس المسحة.
      if (failure.type != FailureType.network &&
          await _serverRecordMatches(ref, attendance)) {
        return;
      }
      throw failure;
    }
  }

  @override
  Future<AppUser> myProfile() {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final snap = await _db
          .doc(FirestorePaths.user(uid))
          .get()
          .timeout(serverConfirmationTimeout);
      final data = snap.data();
      if (data == null) {
        throw const Failure.notFound(
          message: 'لم يتم العثور على بيانات حسابك.',
        );
      }
      try {
        return AppUser.fromMap(uid, data);
      } on FormatException {
        throw const Failure.unknown();
      }
    });
  }

  @override
  Future<List<Group>> myStaffGroups() {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final centerId = await _myCenterId();
      final col = _db.collection(FirestorePaths.groups(centerId));
      // المساعد بيشوف مجموعاته من assistantIds بس (الدورين منفصلين: خانة
      // المعلم teacherId مش بتخلي حد مساعد). استعلام مقيّد بالـ uid نفسه عشان
      // يعدي من الـ Rules (rules are not filters).
      final snaps = await Future.wait([
        col
            .where('assistantIds', arrayContains: uid)
            .get()
            .timeout(serverConfirmationTimeout),
      ]);
      final byId = <String, Group>{};
      for (final snap in snaps) {
        for (final doc in snap.docs) {
          try {
            byId[doc.id] = Group.fromMap(doc.id, doc.data());
          } on FormatException {
            continue; // مستند تالف: بنتخطاه
          }
        }
      }
      return byId.values.toList();
    });
  }

  @override
  Future<List<Session>> todaySessions({DateTime? now}) {
    return ErrorMapper.guard(() async {
      final centerId = await _myCenterId();
      final groups = await myStaffGroups();
      if (groups.isEmpty) return const <Session>[];
      final cairo = tz.getLocation('Africa/Cairo');
      final n = tz.TZDateTime.from(now ?? DateTime.now(), cairo);
      final dayStart = tz.TZDateTime(cairo, n.year, n.month, n.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final col = _db.collection(FirestorePaths.sessions(centerId));
      // استعلام لكل مجموعة مقيّد بـ groupId: القاعدة بتتحقق من التعيين على
      // resource.data.groupId وهو ثابت لكل نتايج الاستعلام، فالقراءة بتعدي
      // للمساعد المعيّن من غير تعديل في الـ Rules.
      // ملحوظة: محتاج Index مركّب (groupId + startAt) — Firestore بيدي
      // رابط إنشائه في الخطأ أول تشغيل.
      final snaps = await Future.wait([
        for (final group in groups)
          col
              .where('groupId', isEqualTo: group.id)
              .where(
                'startAt',
                isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart),
              )
              .where('startAt', isLessThan: Timestamp.fromDate(dayEnd))
              .orderBy('startAt')
              .get()
              .timeout(serverConfirmationTimeout),
      ]);
      final byId = <String, Session>{};
      for (final snap in snaps) {
        for (final doc in snap.docs) {
          try {
            byId[doc.id] = Session.fromMap(doc.id, doc.data());
          } on FormatException {
            continue; // مستند تالف: بنتخطاه
          }
        }
      }
      final out = byId.values.toList()
        ..sort((a, b) => a.startAt.compareTo(b.startAt));
      return out;
    });
  }

  @override
  Future<Session> sessionById(String sessionId) {
    return ErrorMapper.guard(() async {
      final centerId = await _myCenterId();
      final snap = await _db
          .doc(FirestorePaths.session(centerId, sessionId))
          .get()
          .timeout(serverConfirmationTimeout);
      final data = snap.data();
      if (data == null) throw const Failure.notFound();
      try {
        return Session.fromMap(snap.id, data);
      } on FormatException {
        throw const Failure.unknown();
      }
    });
  }

  @override
  Future<Group> groupById(String groupId) {
    return ErrorMapper.guard(() async {
      final centerId = await _myCenterId();
      final snap = await _db
          .doc(FirestorePaths.group(centerId, groupId))
          .get()
          .timeout(serverConfirmationTimeout);
      final data = snap.data();
      if (data == null) throw const Failure.notFound();
      try {
        return Group.fromMap(snap.id, data);
      } on FormatException {
        throw const Failure.unknown();
      }
    });
  }

  @override
  Future<Set<String>> groupStudentIds(String centerId, String groupId) {
    return ErrorMapper.guard(() async {
      _requireUid();
      // العضوية متخزنة على مستند الطالب (groupIds)، مش على مستند المجموعة.
      final snap = await _db
          .collection(FirestorePaths.students(centerId))
          .where('groupIds', arrayContains: groupId)
          .get()
          .timeout(serverConfirmationTimeout);
      final ids = <String>{};
      for (final doc in snap.docs) {
        try {
          final student = Student.fromMap(doc.id, doc.data());
          if (!student.isArchived) ids.add(student.id);
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }
      return ids;
    });
  }

  @override
  Future<List<Student>> groupStudents(String centerId, String groupId) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final snap = await _db
          .collection(FirestorePaths.students(centerId))
          .where('groupIds', arrayContains: groupId)
          .get()
          .timeout(serverConfirmationTimeout);
      final out = <Student>[];
      for (final doc in snap.docs) {
        try {
          out.add(Student.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }
      return out;
    });
  }

  @override
  Future<List<Attendance>> sessionAttendance(String centerId, String sessionId) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final snap = await _db
          .collection(FirestorePaths.attendance(centerId))
          .where('sessionId', isEqualTo: sessionId)
          .get()
          .timeout(serverConfirmationTimeout);
      final out = <Attendance>[];
      for (final doc in snap.docs) {
        try {
          out.add(Attendance.fromMap(doc.id, doc.data()));
        } on FormatException {
          continue; // مستند تالف: بنتخطاه
        }
      }
      return out;
    });
  }

  @override
  Future<int> lateAfterMinutes(String centerId) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final snap = await _db
          .doc(FirestorePaths.center(centerId))
          .get()
          .timeout(serverConfirmationTimeout);
      final raw = snap.data()?['lateAfterMinutes'];
      return raw is int ? raw : ScanValidator.defaultLateAfterMinutes;
    });
  }

  @override
  Future<ScanSetup> prepareScanSetup(String sessionId) {
    return ErrorMapper.guard(() async {
      final centerId = await _myCenterId();
      final session = await sessionById(sessionId);
      if (session.isCancelled) {
        throw const Failure.validation('الحصة دي ملغاة.');
      }
      final studentIds = await groupStudentIds(centerId, session.groupId);
      final lateAfter = await lateAfterMinutes(centerId);
      // [P1-خطوة4] علامات الدفع للشهر الحالي. فشلها (أوفلاين مثلًا) مش
      // بيعطّل المسح: null = الحالة غير معروفة لكل الطلاب.
      final now = DateTime.now();
      Map<String, bool>? paidByStudentId;
      try {
        paidByStudentId = await groupMonthPaymentStatus(
          centerId,
          session.groupId,
          year: now.year,
          month: now.month,
        );
      } on Failure catch (_) {
        paidByStudentId = null;
      }
      // مجموعة فاضية بترمي Failure.validation جوه forSession.
      return ScanSetup.forSession(
        session: session,
        groupStudentIds: studentIds,
        lateAfterMinutes: lateAfter,
        paidByStudentId: paidByStudentId,
        paymentStatusMonth: paidByStudentId == null
            ? null
            : Payment.monthKey(now.year, now.month),
      );
    });
  }

  @override
  Future<Map<String, bool>> groupMonthPaymentStatus(
    String centerId,
    String groupId, {
    required int year,
    required int month,
  }) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final key = Payment.monthKey(year, month);
      // فلترين equality بس = مفيش composite index.
      // Source.server عمدًا: الكاش الفاضي أوفلاين بيرجّع نجاح فاضي فيخلي
      // كل الطلاب "غير مدفوع" غلط. عايزين الأوفلاين يفشل → غير معروف،
      // والنجاح الفاضي يبقى معناه أكيد: مفيش حد في المجموعة دافع الشهر ده.
      final snap = await _db
          .collection(FirestorePaths.paymentStatus(centerId))
          .where('groupId', isEqualTo: groupId)
          .where('month', isEqualTo: key)
          .get(const GetOptions(source: Source.server))
          .timeout(serverConfirmationTimeout);
      final out = <String, bool>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        final sid = data['studentId'];
        final paid = data['paid'];
        if (sid is String && paid is bool) out[sid] = paid;
      }
      return out;
    });
  }

  Future<void> _confirmMatchingServerRecord(
    DocumentReference<Map<String, dynamic>> ref,
    Attendance expected,
  ) async {
    final snap = await ref
        .get(const GetOptions(source: Source.server))
        .timeout(serverConfirmationTimeout);
    if (!_matches(snap.data(), expected)) {
      throw const Failure.unknown(
        message: 'تعذر تأكيد حفظ الحضور على السيرفر.',
      );
    }
  }

  Future<bool> _serverRecordMatches(
    DocumentReference<Map<String, dynamic>> ref,
    Attendance expected,
  ) async {
    try {
      final snap = await ref
          .get(const GetOptions(source: Source.server))
          .timeout(serverConfirmationTimeout);
      return _matches(snap.data(), expected);
    } on Object {
      return false;
    }
  }

  bool _matches(Map<String, dynamic>? data, Attendance expected) =>
      data?['sessionId'] == expected.sessionId &&
      data?['studentId'] == expected.studentId;

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }

  /// سنتر المستخدم الحالي من `users/{uid}.centerId` (نفس أسلوب باقي الـ
  /// repositories). مفيش سنتر = الحساب لسه ما اتربطش.
  Future<String> _myCenterId() async {
    final uid = _requireUid();
    final snap = await _db
        .doc(FirestorePaths.user(uid))
        .get()
        .timeout(serverConfirmationTimeout);
    final centerId = snap.data()?['centerId'];
    if (centerId is! String) {
      throw const Failure.permission(
        message: 'حسابك غير مرتبط بأي سنتر بعد.',
      );
    }
    return centerId;
  }
}
