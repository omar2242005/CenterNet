import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/students/models/student.dart';

void main() {
  final fakeServerTime = Timestamp.fromDate(DateTime.utc(2026, 11, 1));

  Student make({List<String> groupIds = const ['g1']}) => Student.create(
        id: 's7',
        centerId: 'c1',
        studentNo: 7,
        fullName: '  أحمد محمد  ',
        searchKey: 'احمد محمد',
        phone: '01012345678',
        grade: 'تالتة ثانوي',
        createdBy: 'adminA',
        groupIds: groupIds,
      );

  group('create', () {
    test('بيقص الاسم وبيبدأ active', () {
      final s = make();
      expect(s.fullName, 'أحمد محمد');
      expect(s.status, StudentStatus.active);
      expect(s.isArchived, isFalse);
    });

    test('بيشيل تكرار المجموعات', () {
      expect(make(groupIds: ['g1', 'g2', 'g1']).groupIds, ['g1', 'g2']);
    });

    test('بيرفض id أو centerId فيهم _ أو فاضيين', () {
      Student build({String id = 's7', String centerId = 'c1'}) =>
          Student.create(
            id: id,
            centerId: centerId,
            studentNo: 1,
            fullName: 'علي',
            searchKey: 'علي',
            phone: '',
            grade: '',
            createdBy: 'a',
          );
      expect(() => build(id: 's_7'), throwsArgumentError);
      expect(() => build(id: ''), throwsArgumentError);
      expect(() => build(centerId: 'c_1'), throwsArgumentError);
    });

    test('بيرفض رقم تسلسلي أقل من 1 واسم فاضي وsearchKey فاضي', () {
      Student build({int no = 1, String name = 'علي', String key = 'علي'}) =>
          Student.create(
            id: 's1',
            centerId: 'c1',
            studentNo: no,
            fullName: name,
            searchKey: key,
            phone: '',
            grade: '',
            createdBy: 'a',
          );
      expect(() => build(no: 0), throwsArgumentError);
      expect(() => build(name: '   '), throwsArgumentError);
      expect(() => build(key: ''), throwsArgumentError);
    });
  });

  group('toCreateMap / fromMap', () {
    test('الحقول المتوقعة بالظبط', () {
      final m = make().toCreateMap(createdAt: fakeServerTime);
      expect(m.keys.toSet(), {
        'centerId', 'studentNo', 'fullName', 'searchKey', 'phone', 'grade',
        'groupIds', 'status', 'createdAt', 'createdBy',
      });
      expect(m['status'], 'active');
      expect(m['studentNo'], 7);
    });

    test('round trip', () {
      final original = make(groupIds: ['g1', 'g2']);
      final back = Student.fromMap(
        original.id,
        original.toCreateMap(createdAt: fakeServerTime),
      );
      expect(back.id, 's7');
      expect(back.centerId, 'c1');
      expect(back.studentNo, 7);
      expect(back.fullName, 'أحمد محمد');
      expect(back.searchKey, 'احمد محمد');
      expect(back.phone, '01012345678');
      expect(back.grade, 'تالتة ثانوي');
      expect(back.groupIds, ['g1', 'g2']);
      expect(back.status, StudentStatus.active);
      expect(back.createdBy, 'adminA');
      expect(back.createdAt, isNotNull);
    });

    test('createdAt = null لو السيرفر لسه ماكتبش الوقت', () {
      final m = make().toCreateMap(createdAt: fakeServerTime)
        ..['createdAt'] = null;
      expect(Student.fromMap('s7', m).createdAt, isNull);
    });

    test('fromMap بترمي FormatException لو ناقص حقل أو الحالة غريبة', () {
      final good = make().toCreateMap(createdAt: fakeServerTime);
      for (final k in ['centerId', 'fullName', 'searchKey', 'createdBy']) {
        expect(
          () => Student.fromMap('s7', {...good}..remove(k)),
          throwsFormatException,
          reason: k,
        );
      }
      expect(
        () => Student.fromMap('s7', {...good}..remove('studentNo')),
        throwsFormatException,
      );
      expect(
        () => Student.fromMap('s7', {...good, 'status': 'weird'}),
        throwsFormatException,
      );
    });

    test('groupIds ناقصة = قائمة فاضية', () {
      final m = make().toCreateMap(createdAt: fakeServerTime)
        ..remove('groupIds');
      expect(Student.fromMap('s7', m).groupIds, isEmpty);
    });
  });

  group('التعديل والأرشفة', () {
    test('toUpdateMap مش بيلمس الحقول الثابتة', () {
      final m = Student.toUpdateMap(
        fullName: ' علي ',
        searchKey: 'علي',
        phone: '01099999999',
        grade: 'تانية ثانوي',
        groupIds: ['g1', 'g1', 'g3'],
      );
      expect(m.keys.toSet(), {
        'fullName', 'searchKey', 'phone', 'grade', 'groupIds',
      });
      expect(m['fullName'], 'علي');
      expect(m['groupIds'], ['g1', 'g3']);
    });

    test('toUpdateMap بترفض اسم فاضي', () {
      expect(
        () => Student.toUpdateMap(
          fullName: ' ',
          searchKey: 'x',
          phone: '',
          grade: '',
          groupIds: const [],
        ),
        throwsArgumentError,
      );
    });

    test('الأرشفة والاسترجاع بيغيّروا الحالة بس', () {
      expect(Student.toArchiveMap(), {'status': 'archived'});
      expect(Student.toRestoreMap(), {'status': 'active'});
      final archived = Student.fromMap(
        's7',
        {...make().toCreateMap(createdAt: fakeServerTime), 'status': 'archived'},
      );
      expect(archived.isArchived, isTrue);
    });

    test('isInGroup و withGroupIds', () {
      final s = make();
      expect(s.isInGroup('g1'), isTrue);
      expect(s.isInGroup('g2'), isFalse);
      final moved = s.withGroupIds(['g2']);
      expect(moved.isInGroup('g2'), isTrue);
      expect(moved.isInGroup('g1'), isFalse);
      expect(moved.id, s.id);
    });
  });
}
