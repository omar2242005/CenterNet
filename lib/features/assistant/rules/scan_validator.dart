import '../../../core/firestore_paths.dart';

/// نتايج المسح الخمسة (الملف الشامل قسم 7).
enum ScanOutcome {
  /// النص مش بصيغة `centerId:studentId`.
  invalidCode,

  /// الـ centerId مختلف عن سنتر المسّاح.
  otherCenter,

  /// الطالب مش في مجموعة الجلسة (أو مش في الكاش): تحذير ومفيش تسجيل.
  notRegistered,

  /// اتسجل قبل كده، أو كان ملغي ([ScanResult.wasVoided]).
  alreadyRegistered,

  /// تم التسجيل: [ScanResult.timing] بتقول حاضر ولا متأخر.
  recorded,
}

/// توقيت المسح بالنسبة لبداية الحصة.
enum ScanTiming { present, late }

/// حالة سجل الحضور الموجود للطالب في الجلسة دي (لو في).
/// الكالس ده نقي، فالـ caller هو اللي بيحوّل Attendance لقيمة من دول.
enum ExistingAttendance {
  /// مفيش سجل.
  none,

  /// في سجل شغّال.
  active,

  /// في سجل ملغي.
  voided,
}

/// نتيجة مسحة واحدة.
class ScanResult {
  final ScanOutcome outcome;

  /// null بس مع [ScanOutcome.invalidCode].
  final String? studentId;

  /// غير null بس مع [ScanOutcome.recorded].
  final ScanTiming? timing;

  /// true بس مع [ScanOutcome.alreadyRegistered] لو السجل القديم ملغي
  /// ("ملغى سابقًا — راجع المصحح").
  final bool wasVoided;

  const ScanResult._(
    this.outcome, {
    this.studentId,
    this.timing,
    this.wasVoided = false,
  });

  const ScanResult.invalidCode() : this._(ScanOutcome.invalidCode);

  const ScanResult.otherCenter(String studentId)
      : this._(ScanOutcome.otherCenter, studentId: studentId);

  const ScanResult.notRegistered(String studentId)
      : this._(ScanOutcome.notRegistered, studentId: studentId);

  const ScanResult.alreadyRegistered(String studentId, {bool wasVoided = false})
      : this._(
          ScanOutcome.alreadyRegistered,
          studentId: studentId,
          wasVoided: wasVoided,
        );

  const ScanResult.recorded(String studentId, ScanTiming timing)
      : this._(ScanOutcome.recorded, studentId: studentId, timing: timing);

  /// الـ Repository يكتب سجل حضور جديد في الحالة دي بس.
  bool get shouldWrite => outcome == ScanOutcome.recorded;

  @override
  bool operator ==(Object other) =>
      other is ScanResult &&
      other.outcome == outcome &&
      other.studentId == studentId &&
      other.timing == timing &&
      other.wasVoided == wasVoided;

  @override
  int get hashCode => Object.hash(outcome, studentId, timing, wasVoided);

  @override
  String toString() =>
      'ScanResult($outcome, studentId: $studentId, timing: $timing, '
      'wasVoided: $wasVoided)';
}

/// عقل المسح: بياخد نص الـ QR ويرد بواحدة من 5 نتايج.
///
/// كالس نقي: مفيش Flutter ولا Firebase، ومابيكتبش حاجة (الـ Repository هو
/// اللي بيكتب). بيشتغل من الكاش من غير شبكة.
///
/// بيتبني مرة لكل جلسة (بالمعطيات اللي اتحمّلت لما ضغط "تحضير للأوفلاين")
/// وبيتنادى [validate] مع كل مسحة.
class ScanValidator {
  /// مدة التأخير الافتراضية (دقايق) لو مستند السنتر ما فيهوش قيمة.
  static const int defaultLateAfterMinutes = 15;

  /// السنتر بتاع المسّاح.
  final String centerId;

  /// بداية الحصة (لحظة زمنية).
  final DateTime sessionStart;

  /// طلاب مجموعة الجلسة (من الكاش). أي طالب برّه = "غير مسجل".
  final Set<String> groupStudentIds;

  /// بعد [sessionStart] بكام دقيقة يبقى المسح "متأخر".
  final int lateAfterMinutes;

  ScanValidator({
    required this.centerId,
    required this.sessionStart,
    required Set<String> groupStudentIds,
    this.lateAfterMinutes = defaultLateAfterMinutes,
  }) : groupStudentIds = Set<String>.unmodifiable(groupStudentIds) {
    if (centerId.isEmpty) {
      throw ArgumentError.value(centerId, 'centerId', 'مينفعش يكون فاضي');
    }
    if (lateAfterMinutes < 0) {
      throw ArgumentError.value(
        lateAfterMinutes,
        'lateAfterMinutes',
        'مينفعش يكون سالب',
      );
    }
  }

  /// آخر لحظة المسح فيها "حاضر" (شاملة).
  DateTime get presentDeadline =>
      sessionStart.add(Duration(minutes: lateAfterMinutes));

  /// [raw] نص الـ QR زي ما اتقرأ. [now] وقت الجهاز لحظة المسح.
  /// [existingOf] بيسأل: إيه حالة سجل الطالب ده في الجلسة دي؟
  /// (بيتنادى بس لو وصلنا للخطوة 4).
  ScanResult validate(
    String raw, {
    required DateTime now,
    required ExistingAttendance Function(String studentId) existingOf,
  }) {
    // 1) صيغة غلط.
    final parsed = FirestoreIds.tryParseQr(raw);
    if (parsed == null) return const ScanResult.invalidCode();

    // 2) سنتر تاني.
    if (parsed.centerId != centerId) {
      return ScanResult.otherCenter(parsed.studentId);
    }

    // 3) مش في مجموعة الجلسة (أو مش في الكاش): تحذير من غير تسجيل.
    final sid = parsed.studentId;
    if (!groupStudentIds.contains(sid)) {
      return ScanResult.notRegistered(sid);
    }

    // 4) متسجل قبل كده (شغّال أو ملغي).
    switch (existingOf(sid)) {
      case ExistingAttendance.active:
        return ScanResult.alreadyRegistered(sid);
      case ExistingAttendance.voided:
        return ScanResult.alreadyRegistered(sid, wasVoided: true);
      case ExistingAttendance.none:
        break;
    }

    // 5) تسجيل: حاضر لو المسح لحد startAt + lateAfterMinutes، متأخر بعدها.
    final timing =
        now.isAfter(presentDeadline) ? ScanTiming.late : ScanTiming.present;
    return ScanResult.recorded(sid, timing);
  }
}
