import '../rules/scan_validator.dart';

/// كل اللي شاشة المسح محتاجاه عشان تشتغل من غير شبكة: السنتر والجلسة
/// وطلاب المجموعة (من الكاش) ووقت البداية.
///
/// في الخطوة الجاية ("تحضير للأوفلاين") هتتبني من الجلسة الحقيقية. دلوقتي
/// [ScanSetup.demo] بيدّي بيانات تجريبية عشان الشاشة تتجرب لوحدها.
class ScanSetup {
  ScanSetup({
    required this.centerId,
    required this.sessionId,
    required this.sessionStart,
    required Set<String> groupStudentIds,
    this.lateAfterMinutes = ScanValidator.defaultLateAfterMinutes,
    this.isDemo = false,
  }) : groupStudentIds = Set<String>.unmodifiable(groupStudentIds);

  /// بيانات تجريبية: سنتر `demo`، خمس طلاب `s1..s5`، والحصة بدأت من 10 دقايق
  /// (يعني المسح "حاضر" لحد ما يعدّي 5 دقايق كمان، وبعدها "متأخر").
  factory ScanSetup.demo({DateTime? now}) {
    final t = now ?? DateTime.now();
    return ScanSetup(
      centerId: demoCenterId,
      sessionId: 'demo_${t.millisecondsSinceEpoch}',
      sessionStart: t.subtract(const Duration(minutes: 10)),
      groupStudentIds: demoStudentIds.toSet(),
      isDemo: true,
    );
  }

  static const String demoCenterId = 'demo';
  static const List<String> demoStudentIds = <String>[
    's1',
    's2',
    's3',
    's4',
    's5',
  ];

  final String centerId;
  final String sessionId;
  final DateTime sessionStart;
  final Set<String> groupStudentIds;
  final int lateAfterMinutes;

  /// true = بيانات تجريبية، والمسحات مش بتتحفظ على الجهاز.
  final bool isDemo;
}
