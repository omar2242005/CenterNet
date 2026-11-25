import '../models/pending_scan.dart';

abstract class AssistantRepository {
  /// يكتب مسحة حضور بعد أن يؤكد السيرفر حفظها.
  ///
  /// يرمي [Failure] عند الفشل؛ الشبكة تعني أن المسحة تظل معلقة، وأي فشل
  /// آخر يمكن أن يتحول إلى مسحة فاشلة قابلة لإعادة المحاولة.
  Future<void> writeAttendance(PendingScan scan);
}
