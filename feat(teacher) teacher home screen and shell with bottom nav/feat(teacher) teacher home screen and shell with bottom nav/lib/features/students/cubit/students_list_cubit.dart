import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import '../../../core/state/view_state.dart';
import '../../../core/utils/arabic_normalizer.dart';
import '../models/student.dart';
import '../repository/students_repository.dart';

class StudentsListState {
  const StudentsListState({
    this.all = const <Student>[],
    this.query = '',
    this.showArchived = false,
    this.loading = true,
    this.failure,
  });

  /// كل الطلاب اللي اتحملوا (نشطين ومؤرشفين).
  final List<Student> all;
  final String query;
  final bool showArchived;
  final bool loading;
  final Failure? failure;

  StudentsListState copyWith({
    List<Student>? all,
    String? query,
    bool? showArchived,
    bool? loading,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return StudentsListState(
      all: all ?? this.all,
      query: query ?? this.query,
      showArchived: showArchived ?? this.showArchived,
      loading: loading ?? this.loading,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  /// الطلاب المعروضين: بعد إخفاء المؤرشفين (لو مش مطلوبين) وبعد البحث.
  List<Student> get visible {
    return <Student>[
      for (final s in all)
        if ((showArchived || !s.isArchived) && _matches(s)) s,
    ];
  }

  bool _matches(Student s) {
    final q = normalizeArabic(query);
    if (q.isEmpty) return true;
    return matchesSearch(s.searchKey, q) ||
        s.studentNo.toString() == q ||
        (q.length >= 3 && s.phone.contains(q));
  }

  /// تحميل · فارغ · خطأ · نجاح.
  ViewState<List<Student>> get view {
    if (loading) return const ViewLoading<List<Student>>();
    final f = failure;
    if (f != null) return ViewFailed<List<Student>>(f);
    return listViewState<Student>(visible);
  }
}

class StudentsListCubit extends Cubit<StudentsListState> {
  StudentsListCubit(this._repo) : super(const StudentsListState());

  final StudentsRepository _repo;

  Future<void> load() async {
    emit(state.copyWith(loading: true, clearFailure: true));
    try {
      final roster = await _repo.loadStudents();
      if (isClosed) return;
      emit(state.copyWith(all: roster.students, loading: false));
    } on Failure catch (f) {
      if (isClosed) return;
      emit(state.copyWith(loading: false, failure: f));
    }
  }

  void setQuery(String query) => emit(state.copyWith(query: query));

  void setShowArchived(bool value) => emit(state.copyWith(showArchived: value));
}
