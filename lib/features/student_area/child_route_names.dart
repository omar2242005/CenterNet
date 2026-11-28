import '../students/models/student.dart';
import 'models/child_data.dart';

/// مسارات شاشات بيانات الطالب (بيستخدمها الطالب وولي الأمر).
/// كلها بتاخد `extra: Student`، ماعدا [exam] (`ExamResult`) و[updates] (`UpdatesArgs`).
abstract final class ChildRoutes {
  static const String schedule = '/child/schedule';
  static const String attendance = '/child/attendance';
  static const String results = '/child/results';
  static const String profile = '/child/profile';
  static const String overview = '/child/overview';
  static const String exam = '/child/exam';
  static const String updates = '/child/updates';
}

/// بارامترات شاشة تفاصيل الامتحان: الطالب صاحب النتيجة + النتيجة نفسها.
/// الطالب مطلوب عشان الشاشة بتفتح جوه هيكل الطالب (التبويبات تفضل ظاهرة).
class ExamDetailsArgs {
  const ExamDetailsArgs(this.student, this.result);

  final Student student;
  final ExamResult result;
}
