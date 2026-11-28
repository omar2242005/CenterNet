import '../models/pending_scan.dart';

enum SyncPhase { ready, offline, syncing, failed, done }

class SyncState {
  const SyncState({
    this.phase = SyncPhase.ready,
    this.records = const <PendingScan>[],
    this.completed = 0,
    this.total = 0,
    this.syncedCount = 0,
    this.message,
  });

  final SyncPhase phase;
  final List<PendingScan> records;
  final int completed;
  final int total;
  final int syncedCount;
  final String? message;

  int get failedCount =>
      records.where((scan) => scan.status == PendingScanStatus.failed).length;

  List<PendingScan> get failed => records
      .where((scan) => scan.status == PendingScanStatus.failed)
      .toList(growable: false);

  bool get isSyncing => phase == SyncPhase.syncing;

  SyncState copyWith({
    SyncPhase? phase,
    List<PendingScan>? records,
    int? completed,
    int? total,
    int? syncedCount,
    String? message,
  }) => SyncState(
    phase: phase ?? this.phase,
    records: records ?? this.records,
    completed: completed ?? this.completed,
    total: total ?? this.total,
    syncedCount: syncedCount ?? this.syncedCount,
    message: message,
  );
}
