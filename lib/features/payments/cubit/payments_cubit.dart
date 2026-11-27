import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../../groups/models/group.dart';
import '../../groups/models/groups_roster.dart';
import '../../groups/repository/groups_repository.dart';
import '../../students/models/student.dart';
import '../../students/models/students_roster.dart';
import '../../students/repository/students_repository.dart';
import '../models/payment.dart';
import '../repositories/payments_repository.dart';

/// فلتر حالة السداد في شاشة المدفوعات.
enum PaymentsFilter { all, paid, unpaid }

/// صف (طالب × مجموعة) في شهر: لو ليه دفعة غير ملغاة يبقى مدفوع، وإلا غير
/// مدفوع والمبلغ المطلوب = `monthlyFee` بتاع المجموعة.
class PaymentRow {
  const PaymentRow({
    required this.student,
    required this.group,
    this.payment,
  });

  final Student student;
  final Group group;

  /// الدفعة المدفوعة للشهر ده (null = غير مدفوع). الملغاة مش بتتحسب.
  final Payment? payment;

  bool get isPaid => payment != null;

  /// المبلغ المعروض بالقروش: المدفوع الفعلي لو مدفوع، وإلا سعر المجموعة.
  int get amountPiasters => payment?.amount.round() ?? group.monthlyFee;
}

class PaymentsState {
  const PaymentsState({
    required this.year,
    required this.month,
    this.rows = const <PaymentRow>[],
    this.groups = const <Group>[],
    this.query = '',
    this.groupId,
    this.filter = PaymentsFilter.all,
    this.loading = true,
    this.busy = false,
    this.failure,
    this.actionFailure,
  });

  /// الشهر المعروض.
  final int year;
  final int month;

  /// كل صفوف الشهر (قبل البحث والفلاتر).
  final List<PaymentRow> rows;

  /// مجموعات السنتر النشطة (لفلتر المجموعة).
  final List<Group> groups;

  final String query;

  /// فلتر مجموعة (null = كل المجموعات).
  final String? groupId;
  final PaymentsFilter filter;

  /// تحميل أولي أو تغيير شهر شغال.
  final bool loading;

  /// تسجيل أو إلغاء شغال دلوقتي.
  final bool busy;

  /// فشل تحميل (بيظهر في جسم الشاشة مع إعادة محاولة).
  final Failure? failure;

  /// فشل تسجيل/إلغاء (بيظهر SnackBar). بيتصفّر مع أي محاولة جديدة.
  final Failure? actionFailure;

  /// الصفوف المعروضة بعد البحث وفلاتر المجموعة والحالة.
  List<PaymentRow> get visible {
    final q = normalizeArabic(query);
    return <PaymentRow>[
      for (final r in rows)
        if ((groupId == null || r.group.id == groupId) &&
            (filter == PaymentsFilter.all ||
                (filter == PaymentsFilter.paid) == r.isPaid) &&
            (q.isEmpty || matchesSearch(r.student.searchKey, q)))
          r,
    ];
  }

  /// تحميل · فارغ · خطأ · نجاح (على الصفوف المعروضة).
  ViewState<List<PaymentRow>> get view {
    if (loading) return const ViewLoading<List<PaymentRow>>();
    final f = failure;
    if (f != null) return ViewFailed<List<PaymentRow>>(f);
    final v = visible;
    if (v.isEmpty) return const ViewEmpty<List<PaymentRow>>();
    return ViewSuccess<List<PaymentRow>>(v);
  }
}

/// شاشة المدفوعات (أدمن): مدفوع/غير مدفوع لكل (طالب × مجموعة) في شهر،
/// مع بحث وفلاتر وتسجيل/إلغاء من نفس الشاشة.
///
/// غير المسددين = قوائم الطلاب في المجموعات النشطة ناقص أصحاب دفعة غير
/// ملغاة في الشهر. الطلاب والمجموعات المؤرشفون مش بيتحسبوا.
class PaymentsCubit extends Cubit<PaymentsState> {
  PaymentsCubit(this._payments, this._groupsRepo, this._studentsRepo)
    : super(_initialState());

  final PaymentsRepository _payments;
  final GroupsRepository _groupsRepo;
  final StudentsRepository _studentsRepo;

  static PaymentsState _initialState() {
    final now = DateTime.now();
    return PaymentsState(year: now.year, month: now.month);
  }

  List<Student> _students = const <Student>[];
  String? _centerId;

  /// تحميل الطلاب والمجموعات ودفعات الشهر وبناء الصفوف.
  Future<void> load() async {
    emit(_copy(loading: true, clearFailure: true));
    try {
      final results = await Future.wait([
        _studentsRepo.loadStudents(),
        _groupsRepo.loadGroups(),
      ]);
      final studentsRoster = results[0] as StudentsRoster;
      final groupsRoster = results[1] as GroupsRoster;
      _students = studentsRoster.students;
      _centerId = studentsRoster.centerId;
      final groups = groupsRoster.groups
          .where((g) => !g.isArchived)
          .toList(growable: false);
      final payments = await _payments.loadMonthPayments(
        studentsRoster.centerId,
        year: state.year,
        month: state.month,
      );
      // [P1-خطوة4] إصلاح علامات المسح للشهر (للدفعات الأقدم من خطوة 4).
      // فشلها مش بيعطّل الشاشة: بتتصلّح في التحميل الجاي.
      try {
        await _payments.backfillMonthPaymentStatus(
          studentsRoster.centerId,
          year: state.year,
          month: state.month,
        );
      } on Failure catch (_) {}
      if (isClosed) return;
      emit(
        _copy(
          rows: _buildRows(_students, groups, payments),
          groups: groups,
          loading: false,
          clearFailure: true,
        ),
      );
    } on Failure catch (f) {
      if (isClosed) return;
      emit(_copy(loading: false, failure: f));
    }
  }

  /// تغيير الشهر المعروض (بتحميل من جديد).
  Future<void> setMonth(int year, int month) async {
    if (year == state.year && month == state.month) return;
    emit(_copy(year: year, month: month));
    await load();
  }

  void setQuery(String query) => emit(_copy(query: query));

  void setGroupFilter(String? groupId) =>
      emit(_copy(groupId: groupId, clearGroup: groupId == null));

  void setFilter(PaymentsFilter filter) => emit(_copy(filter: filter));

  /// تسجيل دفعة لطالب (من كارت غير مدفوع). [amountPiasters] بالقروش.
  /// بيرجّع null لو نجحت، أو الـ Failure (الشيت بيعرضه مكان الفورم).
  Future<Failure?> record({
    required String studentId,
    required String groupId,
    required int year,
    required int month,
    required int amountPiasters,
    String note = '',
  }) async {
    if (state.busy) return null;
    final centerId = _centerId;
    if (centerId == null) return const Failure.notFound();
    emit(_copy(busy: true, clearActionFailure: true));
    try {
      await _payments.recordPayment(
        centerId: centerId,
        studentId: studentId,
        groupId: groupId,
        year: year,
        month: month,
        amount: amountPiasters.toDouble(),
        note: note,
      );
      await _refreshMonthPayments(centerId);
      if (isClosed) return null;
      emit(_copy(busy: false, clearActionFailure: true));
      return null;
    } on Failure catch (f) {
      if (isClosed) return f;
      emit(_copy(busy: false, actionFailure: f));
      return f;
    }
  }

  /// إلغاء دفعة بسبب إلزامي (من كارت مدفوع). بيرجّع null لو نجح.
  Future<Failure?> cancel(Payment payment, {required String reason}) async {
    if (state.busy) return null;
    emit(_copy(busy: true, clearActionFailure: true));
    try {
      await _payments.cancelPayment(payment, reason: reason);
      await _refreshMonthPayments(payment.centerId);
      if (isClosed) return null;
      emit(_copy(busy: false, clearActionFailure: true));
      return null;
    } on Failure catch (f) {
      if (isClosed) return f;
      emit(_copy(busy: false, actionFailure: f));
      return f;
    }
  }

  /// إعادة قراءة دفعات الشهر وإعادة بناء الصفوف (بعد تسجيل أو إلغاء).
  Future<void> _refreshMonthPayments(String centerId) async {
    final payments = await _payments.loadMonthPayments(
      centerId,
      year: state.year,
      month: state.month,
    );
    if (isClosed) return;
    emit(_copy(rows: _buildRows(_students, state.groups, payments)));
  }

  /// بناء صفوف (طالب × مجموعة): النشطين بس، والدفعة المدفوعة لو موجودة.
  static List<PaymentRow> _buildRows(
    List<Student> students,
    List<Group> groups,
    List<Payment> monthPayments,
  ) {
    final groupsById = {for (final g in groups) g.id: g};
    final paidByKey = <String, Payment>{
      for (final p in monthPayments)
        if (p.isPaid) '${p.studentId}:${p.groupId}': p,
    };
    final rows = <PaymentRow>[];
    for (final s in students) {
      if (s.isArchived) continue;
      for (final gid in s.groupIds) {
        final g = groupsById[gid];
        if (g == null) continue; // مجموعة محذوفة أو مؤرشفة
        rows.add(
          PaymentRow(
            student: s,
            group: g,
            payment: paidByKey['${s.id}:$gid'],
          ),
        );
      }
    }
    rows.sort((a, b) {
      final byName = a.student.fullName.compareTo(b.student.fullName);
      if (byName != 0) return byName;
      return a.group.name.compareTo(b.group.name);
    });
    return rows;
  }

  PaymentsState _copy({
    int? year,
    int? month,
    List<PaymentRow>? rows,
    List<Group>? groups,
    String? query,
    String? groupId,
    PaymentsFilter? filter,
    bool? loading,
    bool? busy,
    Failure? failure,
    Failure? actionFailure,
    bool clearGroup = false,
    bool clearFailure = false,
    bool clearActionFailure = false,
  }) {
    return PaymentsState(
      year: year ?? state.year,
      month: month ?? state.month,
      rows: rows ?? state.rows,
      groups: groups ?? state.groups,
      query: query ?? state.query,
      groupId: clearGroup ? null : (groupId ?? state.groupId),
      filter: filter ?? state.filter,
      loading: loading ?? state.loading,
      busy: busy ?? state.busy,
      failure: clearFailure ? null : (failure ?? state.failure),
      actionFailure: clearActionFailure
          ? null
          : (actionFailure ?? state.actionFailure),
    );
  }
}
