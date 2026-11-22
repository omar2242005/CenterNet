import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/groups/models/group_input.dart';
import 'package:flutter_test/flutter_test.dart';

GroupSlot slot(int weekday, int start, {int duration = 90}) => GroupSlot(
      weekday: weekday,
      startMinutes: start,
      durationMinutes: duration,
    );

GroupInput input({
  String name = 'الجبر',
  String teacherId = 't1',
  List<String> assistants = const [],
  int? capacity,
  int fee = 45000,
  List<GroupSlot> slots = const [],
}) =>
    GroupInput(
      name: name,
      teacherId: teacherId,
      assistantIds: assistants,
      capacity: capacity,
      monthlyFee: fee,
      slots: slots,
    );

void main() {
  test('مدخلات سليمة', () {
    expect(
      input(
        assistants: ['a1', 'a2'],
        capacity: 20,
        slots: [slot(4, 1020), slot(6, 1020)],
      ).validate(),
      isNull,
    );
  });

  test('الاسم فاضي أو طويل', () {
    expect(input(name: '   ').validate(), isNotNull);
    expect(input(name: 'ا' * 81).validate(), isNotNull);
    expect(input(name: 'ا' * 80).validate(), isNull);
  });

  test('المعلم مطلوب ومينفعش يبقى مساعد', () {
    expect(input(teacherId: '').validate(), isNotNull);
    expect(input(assistants: ['t1']).validate(), isNotNull);
  });

  test('حد المساعدين 10 (التكرار مبيتعدّش)', () {
    expect(
      input(assistants: List.generate(11, (i) => 'a$i')).validate(),
      isNotNull,
    );
    expect(
      input(assistants: List.generate(10, (i) => 'a$i')).validate(),
      isNull,
    );
    expect(input(assistants: ['a1', 'a1']).validate(), isNull);
  });

  test('السعة والسعر', () {
    expect(input(capacity: 0).validate(), isNotNull);
    expect(input(capacity: 1).validate(), isNull);
    expect(input(fee: -1).validate(), isNotNull);
    expect(input(fee: 0).validate(), isNull);
  });

  test('حد المواعيد 14', () {
    final many = [
      for (var d = 1; d <= 7; d++) ...[slot(d, 600, duration: 60), slot(d, 900, duration: 60)],
    ];
    expect(many.length, 14);
    expect(input(slots: many).validate(), isNull);
    expect(input(slots: [...many, slot(1, 1200)]).validate(), isNotNull);
  });

  test('تداخل المواعيد في نفس اليوم', () {
    expect(
      input(slots: [slot(4, 1020), slot(4, 1050)]).validate(),
      isNotNull,
    );
    // يوم مختلف ← مفيش تداخل.
    expect(input(slots: [slot(4, 1020), slot(5, 1050)]).validate(), isNull);
    // ميعاد بيبدأ لحظة ما التاني بينتهي ← مفيش تداخل.
    expect(input(slots: [slot(4, 1020), slot(4, 1110)]).validate(), isNull);
  });
}
