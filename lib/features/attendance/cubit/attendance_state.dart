import '../../../core/state/view_state.dart';
import '../models/attendance_entry.dart';
import '../rules/attendance_merger.dart';

/// فلتر قائمة الحضور (شرائح فوق القايمة).
enum AttendanceFilter { all, present, late, waiting, failed }

class AttendanceState {
  /// السطور الظاهرة بعد البحث والفلتر. ViewSuccess بقايمة فاضية + بحث/فلتر
  /// نشط = حالة "لا توجد نتائج" (الشاشة بتميزها من [query] و[filter]).
  final ViewState<List<AttendanceEntry>> status;

  /// ملخص الجلسة (للعرض فوق القايمة لو حاببين بعدين؛ المصدر الأساسي
  /// شاشة التفاصيل).
  final AttendanceSummary? summary;

  final String query;
  final AttendanceFilter filter;

  const AttendanceState({
    this.status = const ViewLoading(),
    this.summary,
    this.query = '',
    this.filter = AttendanceFilter.all,
  });

  AttendanceState copyWith({
    ViewState<List<AttendanceEntry>>? status,
    AttendanceSummary? summary,
    String? query,
    AttendanceFilter? filter,
  }) => AttendanceState(
    status: status ?? this.status,
    summary: summary ?? this.summary,
    query: query ?? this.query,
    filter: filter ?? this.filter,
  );
}
