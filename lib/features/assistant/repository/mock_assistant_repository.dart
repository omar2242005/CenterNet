import 'assistant_repository.dart';
import '../models/pending_scan.dart';

class MockAssistantRepository implements AssistantRepository {
  MockAssistantRepository({this.onWriteAttendance});

  final Future<void> Function(PendingScan scan)? onWriteAttendance;
  final List<PendingScan> writes = <PendingScan>[];

  @override
  Future<void> writeAttendance(PendingScan scan) async {
    writes.add(scan);
    await onWriteAttendance?.call(scan);
  }
}
