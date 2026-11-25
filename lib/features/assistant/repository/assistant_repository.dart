import '../../auth/models/app_user.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';
import '../models/pending_scan.dart';
import '../models/scan_setup.dart';

abstract class AssistantRepository {
  /// يكتب مسحة حضور بعد أن يؤكد السيرفر حفظها.
  ///
  /// يرمي [Failure] عند الفشل؛ الشبكة تعني أن المسحة تظل معلقة، وأي فشل
  /// آخر يمكن أن يتحول إلى مسحة فاشلة قابلة لإعادة المحاولة.
  Future<void> writeAttendance(PendingScan scan);

  /// بيانات حساب المساعد المسجّل (الاسم + السنتر).
  Future<AppUser> myProfile();

  /// حصص النهارده (بتوقيت القاهرة) لسنتر المساعد، مرتبة بوقت البداية.
  Future<List<Session>> todaySessions({DateTime? now});

  /// جلسة واحدة بالـ id (من سنتر المساعد). [Failure.notFound] لو مش موجودة.
  Future<Session> sessionById(String sessionId);

  /// مجموعة واحدة بالـ id (من سنتر المساعد). [Failure.notFound] لو مش موجودة.
  Future<Group> groupById(String groupId);

  /// ids الطلاب النشطين في مجموعة. العضوية متخزنة على مستند الطالب
  /// (`groupIds` array-contains)، مش على مستند المجموعة.
  Future<Set<String>> groupStudentIds(String centerId, String groupId);

  /// مدة "متأخر بعد" بالدقايق من مستند السنتر، أو
  /// `ScanValidator.defaultLateAfterMinutes` لو الحقل مش متخزن.
  Future<int> lateAfterMinutes(String centerId);

  /// "تحضير للأوفلاين": يبني [ScanSetup] حقيقي من الجلسة (طلاب المجموعة +
  /// مدة التأخير). القراءات بتملي كاش Firestore فالمسح يشتغل من غير شبكة.
  /// يرمي [Failure] لو الجلسة ملغاة أو المجموعة فاضية أو البيانات مش متاحة.
  Future<ScanSetup> prepareScanSetup(String sessionId);
}
