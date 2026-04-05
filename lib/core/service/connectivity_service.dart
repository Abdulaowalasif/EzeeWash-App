// lib/core/service/connectivity_service.dart

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  ConnectivityService._();

  static final ConnectivityService instance = ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _controller.stream;

  bool _isConnected = true;
  bool get isConnected => _isConnected;

  StreamSubscription? _subscription;

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _isConnected = _hasConnection(result);

    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      final connected = _hasConnection(result);
      if (connected != _isConnected) {
        _isConnected = connected;
        _controller.add(_isConnected);
        debugPrint('[Connectivity] ${_isConnected ? "Online ✓" : "Offline ✗"}');
      }
    });
  }

  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) =>
    r == ConnectivityResult.mobile ||
        r == ConnectivityResult.wifi ||
        r == ConnectivityResult.ethernet ||
        r == ConnectivityResult.vpn);
  }

  void dispose() {
    _subscription?.cancel();
    _controller.close();
  }
}