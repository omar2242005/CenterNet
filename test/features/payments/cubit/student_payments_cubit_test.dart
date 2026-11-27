import 'package:center_net/core/errors/failure.dart';
import 'package:center_net/features/groups/models/group.dart';
import 'package:center_net/features/payments/cubit/student_payments_cubit.dart';
import 'package:center_net/features/payments/models/payment.dart';
import 'package:center_net/features/students/models/student.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../groups/helpers/fake_groups_repository.dart';
import '../helpers/fake_payments_repository.dart';

Student studentWithGroups(List<String> groupIds) {
  return Student.fromMap('s1', <String, dynamic>{
    'centerId': 'c1',
    'studentNo': 7,
    'fullName': 'كريم حسن',
    'searchKey': 'كريم حسن',
    'phone': '01012345678',
    'grade': 'الصف الأول',
    'groupIds': groupIds,
    'status': 'active',
    'createdBy': 'u1',
  });
}

Group groupWithFee(String id, String name, int fee) {
  return Group.fromMap(id, <String, dynamic>{
    'centerId': 'c1',
    'name': name,
    'teacherId': 't1',
    'createdBy': 'u1',
    'assistantIds': <String>[],
    'status': 'active',
    'monthlyFee': fee,
  });
}

void main() {
  late FakePaymentsRepository payments;
  late FakeGroupsRepository groups;
  late StudentPaymentsCubit cubit;

  final student = studentWithGroups(<String>['g1', 'g2']);

  setUp(() {
    payments = FakePaymentsRepository(
      payments: [makePayment(month: 10), makePayment(month: 11)],
    );
    groups = FakeGroupsRepository(
      groups: [
        groupWithFee('g1', 'رياضيات أ', 45000),
        groupWithFee('g2', 'فيزياء', 30000),
        groupWithFee('g9', 'مجموعة تانية', 10000),
      ],
    );
    cubit = StudentPaymentsCubit(payments, groups, student);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('load', () {
    test('بيجيب مجموعات الطالب بس والسجل مرتب الأحدث أولًا', () async {
      await cubit.load();

      final s = cubit.state;
      expect(s.loading, isFalse);
      expect(s.groups.map((g) => g.id), ['g1', 'g2']);
      expect(s.payments.map((p) => p.month), ['202611', '202610']);
      expect(s.failure, isNull);
    });

    test('فشل التحميل بيظهر failure', () async {
      payments.loadFailure = const Failure.network();

      await cubit.load();

      expect(cubit.state.loading, isFalse);
      expect(cubit.state.failure?.type, FailureType.network);
    });
  });

  group('record', () {
    test('تسجيل ناجح بيحدّث السجل', () async {
      await cubit.load();

      final failure = await cubit.record(
        groupId: 'g1',
        year: 2026,
        month: 12,
        amountPiasters: 45000,
        note: 'كاش',
      );

      expect(failure, isNull);
      expect(cubit.state.busy, isFalse);
      expect(cubit.state.payments.first.month, '202612');
      expect(cubit.state.payments.first.amount, 45000);
      expect(payments.calls, contains('record:s1:g1:202612'));
    });

    test('شهر مدفوع قبل كده بيرجّع alreadyExists', () async {
      await cubit.load();

      final failure = await cubit.record(
        groupId: 'g1',
        year: 2026,
        month: 11,
        amountPiasters: 45000,
      );

      expect(failure?.type, FailureType.alreadyExists);
      expect(cubit.state.failure?.type, FailureType.alreadyExists);
      expect(cubit.state.busy, isFalse);
    });

    test('إعادة تسجيل شهر ملغي بتنجح', () async {
      payments.payments.add(makePayment(month: 9, cancelled: true));
      await cubit.load();

      final failure = await cubit.record(
        groupId: 'g1',
        year: 2026,
        month: 9,
        amountPiasters: 40000,
      );

      expect(failure, isNull);
      final p = cubit.state.payments.firstWhere((p) => p.month == '202609');
      expect(p.isPaid, isTrue);
      expect(p.amount, 40000);
    });
  });

  group('cancel', () {
    test('إلغاء بسبب بيحدّث الحالة في السجل', () async {
      await cubit.load();
      final target = cubit.state.payments.first;

      final failure = await cubit.cancel(target, reason: 'اتسجلت بالغلط');

      expect(failure, isNull);
      final updated = cubit.state.payments.firstWhere((p) => p.id == target.id);
      expect(updated.status, PaymentStatus.cancelled);
      expect(updated.cancelReason, 'اتسجلت بالغلط');
    });

    test('فشل الإلغاء بيرجّع الـ failure', () async {
      await cubit.load();
      payments.writeFailure = const Failure.permission();

      final failure = await cubit.cancel(
        cubit.state.payments.first,
        reason: 'سبب',
      );

      expect(failure?.type, FailureType.permission);
      expect(cubit.state.busy, isFalse);
    });
  });
}
