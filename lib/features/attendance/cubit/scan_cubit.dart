import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/firestore_paths.dart';
import '../models/scan_setup.dart';
import '../rules/scan_validator.dart';
import '../services/pending_scan_store.dart';
import '../services/scan_recorder.dart';

/// نوع الرد اللي بيظهر للمسّاح بعد كل مسحة.
enum ScanFeedbackKind {
  recordedPresent,
  recordedLate,
  alreadyRegistered,
  voidedBefore,
  notRegistered,
  otherCenter,
  invalidCode,
  storageError,
}

/// آخر مسحة. [seq] بيزيد مع كل رد (حتى لو نفس النوع) عشان الشاشة تحس بالتغيير.
class ScanFeedback {
  const ScanFeedback({required this.seq, required this.kind, this.studentId});

  final int seq;
  final ScanFeedbackKind kind;
  final String? studentId;
}

class ScanState {
  const ScanState({
    this.feedback,
    this.presentCount = 0,
    this.lateCount = 0,
    this.rejectedCount = 0,
    this.pendingCount = 0,
    this.loadFailed = false,
  });

  final ScanFeedback? feedback;
  final int presentCount;
  final int lateCount;

  /// رمز غير صالح + سنتر تاني + طالب غير مسجل.
  final int rejectedCount;
  final int pendingCount;

  /// التخزين المحلي تالف: المسح متوقف (مفيش فشل صامت).
  final bool loadFailed;

  ScanState copyWith({
    ScanFeedback? feedback,
    int? presentCount,
    int? lateCount,
    int? rejectedCount,
    int? pendingCount,
    bool? loadFailed,
  }) {
    return ScanState(
      feedback: feedback ?? this.feedback,
      presentCount: presentCount ?? this.presentCount,
      lateCount: lateCount ?? this.lateCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      pendingCount: pendingCount ?? this.pendingCount,
      loadFailed: loadFailed ?? this.loadFailed,
    );
  }
}

/// بيربط الكاميرا بـ [ScanValidator]: كل نص QR بيتفحص، والمسحة الناجحة
/// بتتسجل في [ScanRecorder].
class ScanCubit extends Cubit<ScanState> {
  ScanCubit({
    required this.setup,
    required ScanRecorder recorder,
    DateTime Function()? clock,
    this.repeatWindow = const Duration(seconds: 3),
  })  : // الباراميتر المسمّى مينفعش يبدأ بـ _ فمينفعش initializing formal.
        // ignore: prefer_initializing_formals
        _recorder = recorder,
        _clock = clock ?? DateTime.now,
        _validator = ScanValidator(
          centerId: setup.centerId,
          sessionStart: setup.sessionStart,
          groupStudentIds: setup.groupStudentIds,
          lateAfterMinutes: setup.lateAfterMinutes,
        ),
        super(const ScanState());

  final ScanSetup setup;

  /// الكاميرا بتقرا نفس الرمز كذا مرة في الثانية؛ نفس النص جوه الفترة دي
  /// بيتتجاهل عشان المسّاح ميشوفش "مسجّل بالفعل" لرمز لسه ماسحه.
  final Duration repeatWindow;

  final ScanRecorder _recorder;
  final DateTime Function() _clock;
  final ScanValidator _validator;

  final Set<String> _scanned = <String>{};
  String? _lastRaw;
  DateTime? _lastAt;
  bool _busy = false;
  int _seq = 0;

  /// بيحمّل اللي اتسجل قبل كده في الجلسة دي (لمنع التكرار).
  void load() {
    try {
      _scanned
        ..clear()
        ..addAll(_recorder.loadStudentIds(setup.sessionId));
      emit(state.copyWith(pendingCount: _recorder.pendingCount));
    } on FormatException {
      emit(state.copyWith(loadFailed: true));
    }
  }

  /// بتتنادى مع كل نص QR بتقراه الكاميرا (أو الإدخال اليدوي للتجربة).
  Future<void> onCode(String raw) async {
    if (isClosed || state.loadFailed || _busy) return;

    final now = _clock();
    final lastAt = _lastAt;
    if (raw == _lastRaw &&
        lastAt != null &&
        now.difference(lastAt) < repeatWindow) {
      return;
    }
    _lastRaw = raw;
    _lastAt = now;

    _busy = true;
    try {
      final result = _validator.validate(
        raw,
        now: now,
        existingOf: (sid) => _scanned.contains(sid)
            ? ExistingAttendance.active
            : ExistingAttendance.none,
      );

      if (!result.shouldWrite) {
        _emitRejectedOrDuplicate(result);
        return;
      }

      final sid = result.studentId!;
      final added = await _recorder.record(
        PendingScan(
          id: FirestoreIds.attendance(setup.sessionId, sid),
          sessionId: setup.sessionId,
          studentId: sid,
          scannedAt: now,
        ),
      );
      if (isClosed) return;
      _scanned.add(sid);

      if (!added) {
        _push(ScanFeedbackKind.alreadyRegistered, sid);
        return;
      }
      final isLate = result.timing == ScanTiming.late;
      _push(
        isLate
            ? ScanFeedbackKind.recordedLate
            : ScanFeedbackKind.recordedPresent,
        sid,
        presentCount: state.presentCount + (isLate ? 0 : 1),
        lateCount: state.lateCount + (isLate ? 1 : 0),
      );
    } on Object {
      if (!isClosed) _push(ScanFeedbackKind.storageError, null);
    } finally {
      _busy = false;
    }
  }

  void _emitRejectedOrDuplicate(ScanResult result) {
    switch (result.outcome) {
      case ScanOutcome.alreadyRegistered:
        _push(
          result.wasVoided
              ? ScanFeedbackKind.voidedBefore
              : ScanFeedbackKind.alreadyRegistered,
          result.studentId,
        );
      case ScanOutcome.notRegistered:
        _push(ScanFeedbackKind.notRegistered, result.studentId,
            rejected: true);
      case ScanOutcome.otherCenter:
        _push(ScanFeedbackKind.otherCenter, result.studentId, rejected: true);
      case ScanOutcome.invalidCode:
        _push(ScanFeedbackKind.invalidCode, null, rejected: true);
      case ScanOutcome.recorded:
        // مستحيل: shouldWrite بتمنع الوصول هنا.
        throw StateError('recorded مفروض يتسجل مش يترفض');
    }
  }

  void _push(
    ScanFeedbackKind kind,
    String? studentId, {
    int? presentCount,
    int? lateCount,
    bool rejected = false,
  }) {
    int pending;
    try {
      pending = _recorder.pendingCount;
    } on Object {
      pending = state.pendingCount;
    }
    emit(
      state.copyWith(
        feedback: ScanFeedback(
          seq: ++_seq,
          kind: kind,
          studentId: studentId,
        ),
        presentCount: presentCount,
        lateCount: lateCount,
        rejectedCount: state.rejectedCount + (rejected ? 1 : 0),
        pendingCount: pending,
      ),
    );
  }
}
