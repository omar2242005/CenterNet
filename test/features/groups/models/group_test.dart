import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:center_net/features/groups/models/group.dart';

void main() {
  final fakeServerTime = Timestamp.fromDate(DateTime.utc(2026, 11, 1));

  // الخميس 5 مساءً لمدة ساعة ونص.
  final slot = GroupSlot(
    weekday: DateTime.thursday,
    startMinutes: 17 * 60,
    durationMinutes: 90,
  );

  Group make({
    String teacherId = 't1',
    List<String> assistantIds = const ['a1'],
    int? capacity = 20,
    int monthlyFee = 45000,
  }) =>
      Group.create(
        id: 'g1',
        centerId: 'c1',
        name: ' فيزياء ثالثة ',
        subject: 'فيزياء',
        grade: 'تالتة ثانوي',
        teacherId: teacherId,
        assistantIds: assistantIds,
        room: 'قاعة 2',
        capacity: capacity,
        monthlyFee: monthlyFee,
        slots: [slot],
        createdBy: 'adminA',
      );

  group('GroupSlot', () {
    test('بيحسب الساعة والدقيقة', () {
      final s = GroupSlot(
        weekday: 1,
        startMinutes: 17 * 60 + 30,
        durationMinutes: 60,
      );
      expect(s.startHour, 17);
      expect(s.startMinute, 30);
    });

    test('بيرفض قيم برا المدى', () {
      expect(
        () => GroupSlot(weekday: 0, startMinutes: 0, durationMinutes: 60),
        throwsArgumentError,
      );
      expect(
        () => GroupSlot(weekday: 8, startMinutes: 0, durationMinutes: 60),
        throwsArgumentError,
      );
      expect(
        () => GroupSlot(weekday: 1, startMinutes: 1440, durationMinutes: 60),
        throwsArgumentError,
      );
      expect(
        () => GroupSlot(weekday: 1, startMinutes: -1, durationMinutes: 60),
        throwsArgumentError,
      );
      expect(
        () => GroupSlot(weekday: 1, startMinutes: 0, durationMinutes: 0),
        throwsArgumentError,
      );
      expect(
        () => GroupSlot(weekday: 1, startMinutes: 0, durationMinutes: 481),
        throwsArgumentError,
      );
    });

    test('round trip والمساواة', () {
      expect(GroupSlot.fromMap(slot.toMap()), slot);
      expect(GroupSlot.fromMap(slot.toMap()).hashCode, slot.hashCode);
    });

    test('fromMap بترمي FormatException لو ناقص أو غير صالح', () {
      expect(
        () => GroupSlot.fromMap({'weekday': 1, 'startMinutes': 0}),
        throwsFormatException,
      );
      expect(
        () => GroupSlot.fromMap(
          {'weekday': 9, 'startMinutes': 0, 'durationMinutes': 60},
        ),
        throwsFormatException,
      );
    });
  });

  group('create', () {
    test('بيقص الاسم وبيبدأ active', () {
      final g = make();
      expect(g.name, 'فيزياء ثالثة');
      expect(g.status, GroupStatus.active);
      expect(g.isArchived, isFalse);
    });

    test('بيرفض id أو centerId فيهم _', () {
      Group build({String id = 'g1', String centerId = 'c1'}) => Group.create(
            id: id,
            centerId: centerId,
            name: 'x',
            subject: '',
            grade: '',
            teacherId: 't1',
            createdBy: 'a',
          );
      expect(() => build(id: 'g_1'), throwsArgumentError);
      expect(() => build(centerId: 'c_1'), throwsArgumentError);
    });

    test('بيرفض اسم فاضي ومعلم فاضي', () {
      Group build({String name = 'x', String teacher = 't1'}) => Group.create(
            id: 'g1',
            centerId: 'c1',
            name: name,
            subject: '',
            grade: '',
            teacherId: teacher,
            createdBy: 'a',
          );
      expect(() => build(name: '  '), throwsArgumentError);
      expect(() => build(teacher: ''), throwsArgumentError);
    });

    test('المعلم مينفعش يبقى مساعد في نفس المجموعة', () {
      expect(
        () => make(teacherId: 't1', assistantIds: ['t1']),
        throwsArgumentError,
      );
    });

    test('بيشيل تكرار المساعدين', () {
      expect(make(assistantIds: ['a1', 'a2', 'a1']).assistantIds, ['a1', 'a2']);
    });

    test('بيرفض سعر سالب وسعة صفر', () {
      expect(() => make(monthlyFee: -1), throwsArgumentError);
      expect(() => make(capacity: 0), throwsArgumentError);
    });
  });

  group('toCreateMap / fromMap', () {
    test('الحقول المتوقعة بالظبط', () {
      final m = make().toCreateMap(createdAt: fakeServerTime);
      expect(m.keys.toSet(), {
        'centerId', 'name', 'subject', 'grade', 'teacherId', 'assistantIds',
        'room', 'capacity', 'monthlyFee', 'slots', 'status', 'createdAt',
        'createdBy',
      });
      expect(m['monthlyFee'], 45000); // بالقروش
      expect(m['status'], 'active');
    });

    test('capacity بتتشال من الـ map لو null', () {
      final m = make(capacity: null).toCreateMap(createdAt: fakeServerTime);
      expect(m.containsKey('capacity'), isFalse);
    });

    test('round trip', () {
      final original = make();
      final back = Group.fromMap(
        original.id,
        original.toCreateMap(createdAt: fakeServerTime),
      );
      expect(back.id, 'g1');
      expect(back.centerId, 'c1');
      expect(back.name, 'فيزياء ثالثة');
      expect(back.subject, 'فيزياء');
      expect(back.grade, 'تالتة ثانوي');
      expect(back.teacherId, 't1');
      expect(back.assistantIds, ['a1']);
      expect(back.room, 'قاعة 2');
      expect(back.capacity, 20);
      expect(back.monthlyFee, 45000);
      expect(back.slots, [slot]);
      expect(back.status, GroupStatus.active);
      expect(back.createdBy, 'adminA');
      expect(back.createdAt, isNotNull);
    });

    test('مستند من غير assistantIds = مفيش مساعدين', () {
      final m = make().toCreateMap(createdAt: fakeServerTime)
        ..remove('assistantIds');
      expect(Group.fromMap('g1', m).assistantIds, isEmpty);
    });

    test('fromMap بترمي FormatException لو ناقص حقل أو الحالة غريبة', () {
      final good = make().toCreateMap(createdAt: fakeServerTime);
      for (final k in ['centerId', 'name', 'teacherId', 'createdBy']) {
        expect(
          () => Group.fromMap('g1', {...good}..remove(k)),
          throwsFormatException,
          reason: k,
        );
      }
      expect(
        () => Group.fromMap('g1', {...good, 'status': 'weird'}),
        throwsFormatException,
      );
    });
  });

  group('التعديل والأرشفة', () {
    test('toUpdateMap مش بيلمس الحقول الثابتة', () {
      final m = Group.toUpdateMap(
        name: ' رياضة ',
        subject: 'رياضة',
        grade: 'تانية ثانوي',
        teacherId: 't2',
        assistantIds: ['a1', 'a1'],
        room: '',
        capacity: 15,
        monthlyFee: 30000,
        slots: [slot],
      );
      expect(m.keys.toSet(), {
        'name', 'subject', 'grade', 'teacherId', 'assistantIds', 'room',
        'capacity', 'monthlyFee', 'slots',
      });
      expect(m['name'], 'رياضة');
      expect(m['assistantIds'], ['a1']);
    });

    test('toUpdateMap بتمسح السعة لو null', () {
      final m = Group.toUpdateMap(
        name: 'x',
        subject: '',
        grade: '',
        teacherId: 't1',
        assistantIds: const [],
        room: '',
        capacity: null,
        monthlyFee: 0,
        slots: const [],
      );
      expect(m['capacity'], isA<FieldValue>());
    });

    test('toUpdateMap بترفض المعلم كمساعد', () {
      expect(
        () => Group.toUpdateMap(
          name: 'x',
          subject: '',
          grade: '',
          teacherId: 't1',
          assistantIds: ['t1'],
          room: '',
          capacity: null,
          monthlyFee: 0,
          slots: const [],
        ),
        throwsArgumentError,
      );
    });

    test('الأرشفة بتغيّر الحالة بس', () {
      expect(Group.toArchiveMap(), {'status': 'archived'});
    });
  });

  group('منطق مساعد', () {
    test('isStaffedBy: المعلم والمساعد بس', () {
      final g = make();
      expect(g.isStaffedBy('t1'), isTrue);
      expect(g.isStaffedBy('a1'), isTrue);
      expect(g.isStaffedBy('x9'), isFalse);
    });

    test('isFull: بدون سعة أبدًا، ومعاها لما العدد يوصلها', () {
      expect(make(capacity: null).isFull(1000), isFalse);
      final g = make(capacity: 20);
      expect(g.isFull(19), isFalse);
      expect(g.isFull(20), isTrue);
    });
  });
}
