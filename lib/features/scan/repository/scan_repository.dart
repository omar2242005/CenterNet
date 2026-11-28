import '../../../core/errors/failure.dart';
import '../models/pending_scan.dart';
import '../models/scan_setup.dart';

/// مسار المسح: كتابة المسحة بعد تأكيد السيرفر، وتحضير بيانات المسح
/// (طلاب المجموعة + مدة التأخير + علامات السداد).
///
/// القراءة العامة للحضور في `features/attendance`؛ هنا الجزء اللي بيكتب
/// واللي بيحضّر للمسح بس.
abstract class ScanRepository {
  /// يكتب مسحة حضور بعد أن يؤكد السيرفر حفظها.
  ///
  /// يرمي [Failure] عند الفشل؛ الشبكة تعني أن المسحة تظل معلقة، وأي فشل
  /// آخر يمكن أن يتحول إلى مسحة فاشلة قابلة لإعادة المحاولة.
  Future<void> writeAttendance(PendingScan scan);

  /// مدة "متأخر بعد" بالدقايق من مستند السنتر، أو
  /// `ScanValidator.defaultLateAfterMinutes` لو الحقل مش متخزن.
  Future<int> lateAfterMinutes(String centerId);

  /// "تحضير للأوفلاين": يبني [ScanSetup] حقيقي من الجلسة (طلاب المجموعة +
  /// مدة التأخير). القراءات بتملي كاش Firestore فالمسح يشتغل من غير شبكة.
  /// يرمي [Failure] لو الجلسة ملغاة أو المجموعة فاضية أو البيانات مش متاحة.
  Future<ScanSetup> prepareScanSetup(String sessionId);

  /// [P1-خطوة4] علامات الدفع لطلاب مجموعة في شهر: من `paymentStatus`
  /// (حالة فقط، من غير مبالغ). المفتاح = studentId والقيمة = مدفوع أو لأ.
  /// طالب مفيهوش مستند = غير مدفوع للشهر ده (مش موجود في الـ Map).
  Future<Map<String, bool>> groupMonthPaymentStatus(
    String centerId,
    String groupId, {
    required int year,
    required int month,
  });
}
