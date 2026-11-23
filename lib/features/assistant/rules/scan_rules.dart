import 'scan_result.dart';

class ScanRules {
  static ScanResult validate({
    required dynamic input, // TODO: Define input type
    required DateTime currentTime,
  }) {
    // TODO: Implement scan rules logic
    return const Registered();
  }
}
