import 'package:connectivity_plus/connectivity_plus.dart';

/// واجهة صغيرة حتى لا يعتمد الـ Cubit أو اختباراتُه على Plugin الجهاز.
abstract interface class ConnectivityMonitor {
  Future<bool> get isOnline;
  Stream<bool> get onOnlineChanged;
}

class ConnectivityPlusMonitor implements ConnectivityMonitor {
  ConnectivityPlusMonitor([Connectivity? connectivity])
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> get isOnline async =>
      _isOnline(await _connectivity.checkConnectivity());

  @override
  Stream<bool> get onOnlineChanged =>
      _connectivity.onConnectivityChanged.map(_isOnline).distinct();

  static bool _isOnline(List<ConnectivityResult> results) =>
      results.any((result) => result != ConnectivityResult.none);
}
