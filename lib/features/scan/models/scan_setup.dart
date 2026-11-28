import '../../../core/errors/failure.dart';
import '../../sessions/models/session.dart';
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
    Map<String, bool>? paidByStudentId,
    this.paymentStatusMonth,
    this.isDemo = false,
  }) : groupStudentIds = Set<String>.unmodifiable(groupStudentIds),
       paidByStudentId = paidByStudentId == null
           ? null
           : Map<String, bool>.unmodifiable(paidByStudentId);

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

  /// setup حقيقي من جلسة حقيقية ("تحضير للأوفلاين").
  ///
  /// [groupStudentIds] = طلاب مجموعة الجلسة من Firestore. مجموعة فاضية
  /// معناها إن المسح هيرفض كل الطلاب، فده خطأ تحضير (Failure.validation)
  /// ومينفعش نفتح الماسح ببيانات ناقصة.
  factory ScanSetup.forSession({
    required Session session,
    required Set<String> groupStudentIds,
    int lateAfterMinutes = ScanValidator.defaultLateAfterMinutes,
    Map<String, bool>? paidByStudentId,
    String? paymentStatusMonth,
  }) {
    if (groupStudentIds.isEmpty) {
      throw const Failure.validation(
        'مفيش طلاب مسجّلين في مجموعة الحصة دي. راجع إدارة السنتر.',
      );
    }
    return ScanSetup(
      centerId: session.centerId,
      sessionId: session.id,
      sessionStart: session.startAt,
      groupStudentIds: groupStudentIds,
      lateAfterMinutes: lateAfterMinutes,
      paidByStudentId: paidByStudentId,
      paymentStatusMonth: paymentStatusMonth,
      isDemo: false,
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

  /// [P1-خطوة4] علامات دفع طلاب المجموعة لشهر [paymentStatusMonth]:
  /// المفتاح = studentId، القيمة = مدفوع أو لأ. طالب مش موجود = غير مدفوع.
  /// null = العلامات ما اتحمّلتش (أوفلاين وقت التحضير) فالحالة غير معروفة.
  final Map<String, bool>? paidByStudentId;

  /// الشهر (`yyyyMM`) اللي [paidByStudentId] بيخصه. لو المسح حصل في شهر
  /// تاني (تحضير آخر الشهر ومسح أول اللي بعده) الحالة بتتحسب غير معروفة.
  final String? paymentStatusMonth;
}
