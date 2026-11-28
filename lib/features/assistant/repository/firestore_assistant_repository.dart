import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../auth/models/app_user.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import 'assistant_repository.dart';

/// قراءات شاشات المساعد من Firestore: حسابه، ومجموعاته، وحصص النهارده.
///
/// الكتابة (الحضور والمسح) اتنقلت لـ `features/scan`، والقراءات المشتركة
/// للحضور في `features/attendance`.
class FirestoreAssistantRepository implements AssistantRepository {
  FirestoreAssistantRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration serverConfirmationTimeout = Duration(seconds: 20);

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
