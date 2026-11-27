import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../groups/models/group.dart';
import '../../groups/repository/groups_repository.dart';
import '../../students/models/student.dart';
import '../models/payment.dart';
import '../repositories/payments_repository.dart';

class StudentPaymentsState {
  const StudentPaymentsState({
    required this.student,
    required this.groups,
    required this.payments,
    this.loading = false,
    this.busy = false,
    this.failure,
  });

  final Student student;

  /// مجموعات الطالب (منها بتتملّى اقتراحات المبلغ).
  final List<Group> groups;

  /// سجل السداد، الأحدث أولًا.
  final List<Payment> payments;

  /// تحميل أولي شغال.
  final bool loading;

  /// تسجيل أو إلغاء شغال دلوقتي.
  final bool busy;

  /// آخر فشل (بيتصفّر مع أي محاولة جديدة).
  final Failure? failure;
}

/// حساب الرسوم بتاع طالب واحد: سجل السداد + تسجيل وإلغاء (أدمن).
class StudentPaymentsCubit extends Cubit<StudentPaymentsState> {
  StudentPaymentsCubit(this._payments, this._groupsRepo, Student student)
    : super(
        StudentPaymentsState(
          student: student,
          groups: const <Group>[],
          payments: const <Payment>[],
          loading: true,
        ),
      );

  final PaymentsRepository _payments;
  final GroupsRepository _groupsRepo;

  /// تحميل مجموعات الطالب وسجل السداد.
  Future<void> load() async {
    final student = state.student;
    emit(
      StudentPaymentsState(
        student: student,
        groups: state.groups,
        payments: state.payments,
        loading: true,
      ),
    );
    try {
      final roster = await _groupsRepo.loadGroups();
      final myGroups = roster.groups
          .where((g) => student.groupIds.contains(g.id))
          .toList(growable: false);
      final payments = await _payments.loadStudentPayments(
        student.centerId,
        student.id,
      );
      if (isClosed) return;
      emit(
        StudentPaymentsState(
          student: student,
          groups: myGroups,
          payments: payments,
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(
        StudentPaymentsState(
          student: student,
          groups: state.groups,
          payments: state.payments,
          failure: f,
        ),
      );
    }
  }

  /// تسجيل دفعة. [amountPiasters] بالقروش (450 ج.م = 45000).
  /// بيرجّع null لو نجحت، أو الـ Failure لو فشلت (الشاشة بتعرضه مكان الفورم).
  Future<Failure?> record({
    required String groupId,
    required int year,
    required int month,
    required int amountPiasters,
    String note = '',
  }) async {
    if (state.busy) return null;
    final student = state.student;
    emit(
      StudentPaymentsState(
        student: student,
        groups: state.groups,
        payments: state.payments,
        busy: true,
      ),
    );
    try {
      await _payments.recordPayment(
        centerId: student.centerId,
        studentId: student.id,
        groupId: groupId,
        year: year,
        month: month,
        amount: amountPiasters.toDouble(),
        note: note,
      );
      final payments = await _payments.loadStudentPayments(
        student.centerId,
        student.id,
      );
      if (isClosed) return null;
      emit(
        StudentPaymentsState(
          student: student,
          groups: state.groups,
          payments: payments,
        ),
      );
      return null;
    } on Failure catch (f) {
      if (isClosed) return f;
      emit(
        StudentPaymentsState(
          student: student,
          groups: state.groups,
          payments: state.payments,
          failure: f,
        ),
      );
      return f;
    }
  }

  /// إلغاء دفعة بسبب إلزامي. بيرجّع null لو نجح، أو الـ Failure.
  Future<Failure?> cancel(Payment payment, {required String reason}) async {
    if (state.busy) return null;
    final student = state.student;
    emit(
      StudentPaymentsState(
        student: student,
        groups: state.groups,
        payments: state.payments,
        busy: true,
      ),
    );
    try {
      await _payments.cancelPayment(payment, reason: reason);
      final payments = await _payments.loadStudentPayments(
        student.centerId,
        student.id,
      );
      if (isClosed) return null;
      emit(
        StudentPaymentsState(
          student: student,
          groups: state.groups,
          payments: payments,
        ),
      );
      return null;
    } on Failure catch (f) {
      if (isClosed) return f;
      emit(
        StudentPaymentsState(
          student: student,
          groups: state.groups,
          payments: state.payments,
          failure: f,
        ),
      );
      return f;
    }
  }
}
