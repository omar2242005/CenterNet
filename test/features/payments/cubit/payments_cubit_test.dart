import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/core/state/view_state.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/payments/cubit/payments_cubit.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../groups/helpers/fake_groups_repository.dart';
import '../../students/helpers/fake_students_repository.dart';
import '../helpers/fake_payments_repository.dart';

Student studentWithGroups(String id, String name, List<String> groupIds) {
  return Student.fromMap(id, <String, dynamic>{
    'centerId': 'c1',
    'studentNo': 7,
    'fullName': name,
    'searchKey': name,
    'phone': '01012345678',
    'grade': 'الصف الأول',
    'groupIds': groupIds,
    'status': 'active',
    'createdBy': 'u1',
  });
}

Student archivedStudent(String id, List<String> groupIds) {
  return Student.fromMap(id, <String, dynamic>{
    'centerId': 'c1',
    'studentNo': 9,
    'fullName': 'طالب مؤرشف',
    'searchKey': 'طالب مؤرشف',
    'phone': '01012345678',
    'grade': 'الصف الأول',
    'groupIds': groupIds,
    'status': 'archived',
    'createdBy': 'u1',
  });
}

Group groupWithFee(String id, String name, int fee, {bool archived = false}) {
  return Group.fromMap(id, <String, dynamic>{
    'centerId': 'c1',
    'name': name,
    'teacherId': 't1',
    'createdBy': 'u1',
    'assistantIds': <String>[],
    'status': archived ? 'archived' : 'active',
    'monthlyFee': fee,
  });
}

void main() {
  late FakePaymentsRepository payments;
  late FakeGroupsRepository groups;
  late FakeStudentsRepository students;
  late PaymentsCubit cubit;

  // كريم في مجموعتين، سارة في واحدة، طالب مؤرشف (مش بيتحسب)، ومجموعة
  // مؤرشفة (مش بتتحسب). شهر الاختبار ثابت: 202611.
  setUp(() {
    payments = FakePaymentsRepository();
    groups = FakeGroupsRepository(
      groups: [
        groupWithFee('g1', 'رياضيات أ', 45000),
        groupWithFee('g2', 'فيزياء', 30000),
        groupWithFee('g3', 'قديمة', 10000, archived: true),
      ],
    );
    students = FakeStudentsRepository(
      students: [
        studentWithGroups('s1', 'كريم حسن', ['g1', 'g2']),
        studentWithGroups('s2', 'سارة علي', ['g1']),
        studentWithGroups('s3', 'مؤرشف مجموعة', ['g3']),
        archivedStudent('s4', ['g1']),
      ],
    );
    cubit = PaymentsCubit(payments, groups, students);
  });

  tearDown(() async {
    await cubit.close();
  });

  /// تحميل شهر الاختبار الثابت 202611. لو هو الشهر الحالي (الكيوبت بيبدأ
  /// عليه) بنحمّل مباشرة، وإلا بنبدّل له (setMonth بتتجاهل نفس الشهر).
  Future<void> loadNovember() {
    if (cubit.state.year == 2026 && cubit.state.month == 11) {
      return cubit.load();
    }
    return cubit.setMonth(2026, 11);
  }

  test('التحميل: صف لكل (طالب × مجموعة) نشطة، مرتبة بالاسم', () async {
    await loadNovember();

    final rows = cubit.state.rows;
    expect(rows.length, 3); // s1×g1, s1×g2, s2×g1
    expect(rows.map((r) => r.student.fullName), [
      'سارة علي',
      'كريم حسن',
      'كريم حسن',
    ]);
    expect(rows.every((r) => !r.isPaid), isTrue);
    expect(rows.first.amountPiasters, 45000); // سعر المجموعة
  });

  test('دفعة مدفوعة بتخلي الصف مدفوع بمبلغها، والملغاة بتفضل غير مدفوع', () async {
    payments.payments.addAll([
      makePayment(studentId: 's1', groupId: 'g1', amount: 50000),
      makePayment(studentId: 's2', groupId: 'g1', cancelled: true),
    ]);
    await loadNovember();

    final rows = cubit.state.rows;
    final paidRow = rows.singleWhere(
      (r) => r.student.id == 's1' && r.group.id == 'g1',
    );
    expect(paidRow.isPaid, isTrue);
    expect(paidRow.amountPiasters, 50000);
    final cancelledRow = rows.singleWhere((r) => r.student.id == 's2');
    expect(cancelledRow.isPaid, isFalse);
  });

  test('الفلاتر: مدفوع/غير مدفوع ومجموعة وبحث بالاسم', () async {
    payments.payments.add(makePayment(studentId: 's1', groupId: 'g1'));
    await loadNovember();

    cubit.setFilter(PaymentsFilter.paid);
    expect(cubit.state.visible.map((r) => r.student.id), ['s1']);

    cubit.setFilter(PaymentsFilter.unpaid);
    cubit.setGroupFilter('g2');
    expect(
      cubit.state.visible.map((r) => '${r.student.id}:${r.group.id}'),
      ['s1:g2'],
    );

    cubit.setGroupFilter(null);
    cubit.setFilter(PaymentsFilter.all);
    cubit.setQuery('سارة');
    expect(cubit.state.visible.map((r) => r.student.id), ['s2']);
  });

  test('تغيير الشهر بيعيد التحميل من المستودع', () async {
    await loadNovember();
    expect(payments.calls, contains('month:202611'));

    payments.payments.add(makePayment(month: 10));
    await cubit.setMonth(2026, 10);
    expect(payments.calls, contains('month:202610'));
    final paid = cubit.state.rows.where((r) => r.isPaid);
    expect(paid.length, 1);
  });

  test('تسجيل من الشاشة: الصف بيتحوّل لمدفوع بعد النجاح', () async {
    await loadNovember();
    final failure = await cubit.record(
      studentId: 's2',
      groupId: 'g1',
      year: 2026,
      month: 11,
      amountPiasters: 45000,
    );

    expect(failure, isNull);
    expect(payments.calls, contains('record:s2:g1:202611'));
    final row = cubit.state.rows.singleWhere((r) => r.student.id == 's2');
    expect(row.isPaid, isTrue);
    expect(cubit.state.busy, isFalse);
  });

  test('شهر مدفوع قبل كده بيرجّع alreadyExists والحالة ما بتتغيرش', () async {
    payments.payments.add(makePayment(studentId: 's2', groupId: 'g1'));
    await loadNovember();

    final failure = await cubit.record(
      studentId: 's2',
      groupId: 'g1',
      year: 2026,
      month: 11,
      amountPiasters: 45000,
    );

    expect(failure?.type, FailureType.alreadyExists);
    expect(cubit.state.actionFailure?.type, FailureType.alreadyExists);
  });

  test('إلغاء دفعة بسبب: الصف بيرجع غير مدفوع', () async {
    final payment = makePayment(studentId: 's1', groupId: 'g1');
    payments.payments.add(payment);
    await loadNovember();
    expect(
      cubit.state.rows.singleWhere((r) => r.student.id == 's1' && r.group.id == 'g1').isPaid,
      isTrue,
    );

    final failure = await cubit.cancel(payment, reason: 'اتسجلت بالغلط');

    expect(failure, isNull);
    expect(payments.calls, contains('cancel:${payment.id}'));
    final row = cubit.state.rows.singleWhere(
      (r) => r.student.id == 's1' && r.group.id == 'g1',
    );
    expect(row.isPaid, isFalse);
  });

  test('فشل التحميل بيظهر حالة خطأ', () async {
    payments.loadFailure = const Failure.network();
    await loadNovember();

    expect(cubit.state.view, isA<ViewFailed<List<PaymentRow>>>());
  });

  test('مفيش طلاب في مجموعات: حالة فاضية', () async {
    students = FakeStudentsRepository(students: []);
    cubit = PaymentsCubit(payments, groups, students);
    await loadNovember();

    expect(cubit.state.view, isA<ViewEmpty<List<PaymentRow>>>());
  });
}
