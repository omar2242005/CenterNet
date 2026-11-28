import '../../../core/errors/failure.dart';
import '../../auth/models/app_user.dart';
import '../../groups/models/group.dart';
import '../../sessions/models/session.dart';

/// قراءات خاصة بدور المساعد: حسابه، ومجموعاته، وحصص النهارده بتاعته.
///
/// الحضور والمسح مش هنا: دول مشتركين مع باقي الأدوار في
/// `features/attendance` و`features/scan`.
abstract class AssistantRepository {
  /// بيانات حساب المساعد المسجّل (الاسم + السنتر).
  Future<AppUser> myProfile();

  /// مجموعات المساعد المعيّن فيها (معلمًا أو مساعدًا). الاستعلام مقيّد
  /// بالـ uid نفسه عشان يطابق نطاق الـ Rules (قرار: مفيش قراءة على مستوى
  /// السنتر لغير الأدمن).
  Future<List<Group>> myStaffGroups();

  /// حصص النهارده (بتوقيت القاهرة) لمجموعات المساعد المعيّن فيها بس — مش
  /// السنتر كله — مرتبة بوقت البداية. النطاق الضيق ده مقصود عشان يطابق
  /// الـ Rules من غير أي تعديل فيها.
  Future<List<Session>> todaySessions({DateTime? now});

  /// مجموعة واحدة بالـ id (من سنتر المساعد). [Failure.notFound] لو مش موجودة.
  Future<Group> groupById(String groupId);
}
