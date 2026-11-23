enum PendingScanStatus {
  pending,
  syncing,
  failed,
  synced,
}

class PendingScan {
  final PendingScanStatus status;

  PendingScan({required this.status});
  // TODO: Add more properties
}
