import '../../auth/models/account_type.dart';
import '../../staff/models/staff_member.dart';

/// المكان اللي المستخدم يروحه بعد الدخول.
enum HomeDestination {
  /// أدمن لسه معندوش سنتر.
  createCenter,

  /// موظف لسه معندوش سنتر (محتاج كود دعوة).
  joinCenter,
  admin,
  teacher,
  assistant,

  /// مؤقتًا بالـ accountType (موجة 3 هتحوّلها لـ studentLinks).
  student,
  guardian,

  /// عضو معطّل من الأدمن.
  inactive,

  /// users.centerId موجود بس مفيش عضوية (حالة غير متوقعة).
  noAccess,
}

typedef MembershipInfo = ({StaffMemberRole role, bool active});

/// دالة نقية (من غير Firebase) بتقرر الوجهة.
///
/// * الصلاحيات الحقيقية من `members` بس، و`accountType` للتوجيه فقط.
/// * الطالب وولي الأمر بيتوجّهوا بـ accountType مؤقتًا ومبيتقرالهمش members.
HomeDestination decideHome({
  required AccountType accountType,
  required String? centerId,
  MembershipInfo? membership,
}) {
  if (accountType == AccountType.student) return HomeDestination.student;
  if (accountType == AccountType.guardian) return HomeDestination.guardian;

  if (centerId == null) {
    return accountType == AccountType.admin
        ? HomeDestination.createCenter
        : HomeDestination.joinCenter;
  }
  if (membership == null) return HomeDestination.noAccess;
  if (!membership.active) return HomeDestination.inactive;

  return switch (membership.role) {
    StaffMemberRole.admin => HomeDestination.admin,
    StaffMemberRole.teacher => HomeDestination.teacher,
    StaffMemberRole.assistant => HomeDestination.assistant,
  };
}
