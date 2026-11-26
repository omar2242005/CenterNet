import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failure.dart';
import 'sync_state.dart';
import '../models/pending_scan.dart';
import '../repository/assistant_repository.dart';
import '../services/connectivity_monitor.dart';
import '../services/pending_scan_store.dart';

class SyncCubit extends Cubit<SyncState> {
  SyncCubit(this._repository, this._store, this._connectivity)
    : super(const SyncState());

  final AssistantRepository _repository;
  final PendingScanStore _store;
  final ConnectivityMonitor _connectivity;

  StreamSubscription<bool>? _connectivitySubscription;
  bool _busy = false;
  bool _foreground = true;

  Future<void> load() async {
    try {
      _emitQueue();
      _connectivitySubscription ??= _connectivity.onOnlineChanged.listen((
        online,
      ) {
        if (online && _foreground && _store.unsyncedCount > 0) {
          sync();
        }
      });
      if (!await _connectivity.isOnline && !isClosed) {
        emit(state.copyWith(phase: SyncPhase.offline));
      }
    } on FormatException {
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: SyncPhase.failed,
            message: 'قائمة المسحات المحلية تالفة.',
          ),
        );
      }
    }
  }

  void setForeground(bool value) {
    _foreground = value;
    if (value && _store.unsyncedCount > 0) sync();
  }

  Future<void> sync({bool retryFailed = false}) async {
    if (_busy || isClosed) return;
    _busy = true;
    try {
      if (!await _connectivity.isOnline) {
        if (!isClosed) emit(state.copyWith(phase: SyncPhase.offline));
        return;
      }

      final queue = _store
          .all()
          .where((scan) {
            return scan.status == PendingScanStatus.pending ||
                (retryFailed && scan.status == PendingScanStatus.failed);
          })
          .toList(growable: false);
      if (queue.isEmpty) {
        _emitQueue(phase: SyncPhase.ready);
        return;
      }

      var synced = 0;
      for (var index = 0; index < queue.length; index++) {
        final scan = queue[index];
        if (!isClosed) {
          emit(
            state.copyWith(
              phase: SyncPhase.syncing,
              completed: index,
              total: queue.length,
              syncedCount: synced,
              message: null,
            ),
          );
        }

        if (scan.centerId == null || scan.attendanceStatus == null) {
          await _store.markFailed(scan.id, 'مسحة قديمة ناقصة بيانات المزامنة.');
        } else {
          try {
            await _repository.writeAttendance(scan);
            await _store.markSynced(scan.id);
            synced++;
          } on Failure catch (failure) {
            if (failure.type == FailureType.network) {
              if (!isClosed) {
                _emitQueue(
                  phase: SyncPhase.offline,
                  completed: index,
                  total: queue.length,
                  syncedCount: synced,
                );
              }
              return;
            }
            await _store.markFailed(scan.id, failure.message);
          } on Object {
            await _store.markFailed(scan.id, 'تعذر رفع المسحة. حاول مرة أخرى.');
          }
        }

        if (!isClosed) {
          _emitQueue(
            phase: SyncPhase.syncing,
            completed: index + 1,
            total: queue.length,
            syncedCount: synced,
          );
        }
      }

      // لازم نحتفظ بالعدد قبل إزالة المسحات الناجحة من التخزين المحلي.
      final records = _store.all();
      final failed = records.any((s) => s.status == PendingScanStatus.failed);
      await _store.clearSynced();
      _emitQueue(
        phase: failed ? SyncPhase.failed : SyncPhase.done,
        completed: queue.length,
        total: queue.length,
        syncedCount: synced,
      );
    } on FormatException {
      if (!isClosed) {
        emit(
          state.copyWith(
            phase: SyncPhase.failed,
            message: 'قائمة المسحات المحلية تالفة.',
          ),
        );
      }
    } finally {
      _busy = false;
    }
  }

  void _emitQueue({
    SyncPhase? phase,
    int? completed,
    int? total,
    int? syncedCount,
  }) {
    final records = _store
        .all()
        .where((scan) => scan.status != PendingScanStatus.synced)
        .toList(growable: false);
    emit(
      state.copyWith(
        phase: phase,
        records: records,
        completed: completed,
        total: total,
        syncedCount: syncedCount,
        message: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}
