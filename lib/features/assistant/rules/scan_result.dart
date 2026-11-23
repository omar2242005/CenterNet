sealed class ScanResult {
  const ScanResult();
}

class Registered extends ScanResult {
  const Registered();
}

class AlreadyRecorded extends ScanResult {
  const AlreadyRecorded();
}

class NotInGroup extends ScanResult {
  const NotInGroup();
}

class UnpaidFees extends ScanResult {
  const UnpaidFees();
}

class SavedLocally extends ScanResult {
  const SavedLocally();
}

class Unreadable extends ScanResult {
  const Unreadable();
}
