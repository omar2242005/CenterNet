import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/failure.dart';
import '../../../core/firestore_paths.dart';
import '../../students/models/student.dart';
import '../models/group.dart';
import '../models/group_input.dart';
import '../models/groups_roster.dart';

/// إدارة المجموعات: قراءة (الأدمن: الكل، المعلم/المساعد: مجموعاته)،
/// وإنشاء وتعديل وأرشفة (الأدمن)، وتسجيل الطلاب فيها.
///
/// * الـ Rules هي الحكم. لو المستخدم مش أدمن الكتابة بتترفض → [Failure.permission].
/// * مفيش حذف نهائي: الأرشفة بدل الحذف.
/// * الإنشاء Transaction عشان يفشل فورًا لو أوفلاين (set عادي كان هيتحفظ
///   محليًا ويتكرر لو الأدمن ضغط تاني).
class GroupsRepository {
  GroupsRepository(this._auth, this._db);

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  static const Duration timeout = Duration(seconds: 20);

  /// كل مجموعات السنتر (للأدمن). نشطة ومؤرشفة.
  Future<GroupsRoster> loadGroups() {
    return ErrorMapper.guard(() async {
      final centerId = await _myCenterId(_requireUid());
      final snap = await _db
          .collection(FirestorePaths.groups(centerId))
          .get()
          .timeout(timeout);
      return GroupsRoster(centerId: centerId, groups: _parse(snap.docs));
    });
  }

  /// مجموعات المستخدم الحالي (للمعلم والمساعد): اللي هو معلمها أو في
  /// مساعديها. استعلامين لأن الـ Rules بتشترط إن الاستعلام نفسه يكون مقيّد.
  Future<GroupsRoster> loadMyGroups() {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      final centerId = await _myCenterId(uid);
      final col = _db.collection(FirestorePaths.groups(centerId));

      final results = await Future.wait([
        col.where('teacherId', isEqualTo: uid).get(),
        col.where('assistantIds', arrayContains: uid).get(),
      ]).timeout(timeout);

      final byId = <String, QueryDocumentSnapshot<Map<String, dynamic>>>{};
      for (final snap in results) {
        for (final doc in snap.docs) {
          byId[doc.id] = doc;
        }
      }
      return GroupsRoster(
        centerId: centerId,
        groups: _parse(byId.values),
      );
    });
  }

  /// بينشئ مجموعة جديدة (active). بيرجّع المجموعة المحفوظة.
  Future<Group> createGroup(GroupInput input) {
    return ErrorMapper.guard(() async {
      final uid = _requireUid();
      _check(input);
      final centerId = await _myCenterId(uid);

      final ref = _db.collection(FirestorePaths.groups(centerId)).doc();
      final group = Group.create(
        id: ref.id,
        centerId: centerId,
        name: input.name,
        subject: input.subject,
        grade: input.grade,
        teacherId: input.teacherId,
        assistantIds: input.assistantIds,
        room: input.room,
        capacity: input.capacity,
        monthlyFee: input.monthlyFee,
        slots: input.slots,
        createdBy: uid,
      );
      await _db.runTransaction<void>((tx) async {
        tx.set(ref, group.toCreateMap());
      }).timeout(timeout);
      return group;
    });
  }

  /// بيعدّل بيانات المجموعة (مش الحالة ولا المنشئ).
  Future<Group> updateGroup(Group group, GroupInput input) {
    return ErrorMapper.guard(() async {
      _requireUid();
      _check(input);
      final ref = _groupRef(group);
      await ref
          .update(
            Group.toUpdateMap(
              name: input.name,
              subject: input.subject,
              grade: input.grade,
              teacherId: input.teacherId,
              assistantIds: input.assistantIds,
              room: input.room,
              capacity: input.capacity,
              monthlyFee: input.monthlyFee,
              slots: input.slots,
            ),
          )
          .timeout(timeout);
      return _reload(ref);
    });
  }

  /// أرشفة المجموعة. مفيش استرجاع في الـ Rules الحالية (status بيتغير
  /// بالتعديل العادي، فلو احتجنا استرجاع بنضيفه بعدين).
  Future<Group> archiveGroup(Group group) {
    return ErrorMapper.guard(() async {
      _requireUid();
      final ref = _groupRef(group);
      await ref.update(Group.toArchiveMap()).timeout(timeout);
      return _reload(ref);
    });
  }

  /// بيسجّل الطالب في المجموعة (arrayUnion، فتكرار الضغط آمن).
  /// السعة تحذير في الواجهة بس، مش منع هنا (خطة 3.3).
  Future<void> enrollStudent(Group group, Student student) {
    return ErrorMapper.guard(() async {
      _requireUid();
      if (group.isArchived) {
        throw const Failure.validation('المجموعة مؤرشفة.');
      }
      if (student.isArchived) {
        throw const Failure.validation('الطالب مؤرشف.');
      }
      if (student.centerId != group.centerId) {
        throw const Failure.validation('الطالب من سنتر مختلف.');
      }
      await _studentRef(student).update(<String, dynamic>{
        'groupIds': FieldValue.arrayUnion(<String>[group.id]),
      }).timeout(timeout);
    });
  }

  /// بيشيل الطالب من المجموعة (arrayRemove).
  Future<void> unenrollStudent(Group group, Student student) {
    return ErrorMapper.guard(() async {
      _requireUid();
      await _studentRef(student).update(<String, dynamic>{
        'groupIds': FieldValue.arrayRemove(<String>[group.id]),
      }).timeout(timeout);
    });
  }

  // ------------------------------------------------------------------

  List<Group> _parse(Iterable<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final groups = <Group>[];
    for (final doc in docs) {
      try {
        groups.add(Group.fromMap(doc.id, doc.data()));
      } on FormatException {
        // مستند تالف: بنتخطاه بدل ما نوقّع القائمة كلها.
        continue;
      }
    }
    groups.sort((a, b) => a.name.compareTo(b.name));
    return groups;
  }

  void _check(GroupInput input) {
    final error = input.validate();
    if (error != null) throw Failure.validation(error);
  }

  DocumentReference<Map<String, dynamic>> _groupRef(Group g) =>
      _db.doc(FirestorePaths.group(g.centerId, g.id));

  DocumentReference<Map<String, dynamic>> _studentRef(Student s) =>
      _db.doc(FirestorePaths.student(s.centerId, s.id));

  Future<Group> _reload(DocumentReference<Map<String, dynamic>> ref) async {
    final snap = await ref.get();
    final data = snap.data();
    if (data == null) throw const Failure.notFound();
    try {
      return Group.fromMap(snap.id, data);
    } on FormatException {
      throw const Failure.unknown();
    }
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw const Failure.permission();
    return uid;
  }

  Future<String> _myCenterId(String uid) async {
    final userSnap = await _db.doc(FirestorePaths.user(uid)).get();
    final centerId = userSnap.data()?['centerId'];
    if (centerId is! String) {
      throw const Failure.notFound(
        message: 'أنت غير مرتبط بسنتر.',
      );
    }
    return centerId;
  }
}
