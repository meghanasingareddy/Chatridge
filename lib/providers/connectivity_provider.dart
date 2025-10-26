import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/api_service.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    _initializeConnectivity();
  }
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool _isConnected = false;
  bool _isConnectedToChatridge = false;
  String? _currentSSID;
  String? _currentIP;

  bool get isConnected => _isConnected;
  bool get isConnectedToChatridge => _isConnectedToChatridge;
  String? get currentSSID => _currentSSID;
  String? get currentIP => _currentIP;

  void _initializeConnectivity() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) => _updateConnectionStatus(results),
    );

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(connectivityResults);
    } catch (e) {
      debugPrint('Error checking initial connectivity: $e');
    }
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> results) async {
    try {
      _isConnected = results.any((result) => result != ConnectivityResult.none);

      if (_isConnected) {
        // Check if connected to WiFi
        if (results.contains(ConnectivityResult.wifi)) {
          // Try to get SSID (this might not work on all devices)
          await _checkSSID();
        }
      } else {
        _isConnectedToChatridge = false;
        _currentSSID = null;
        _currentIP = null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error updating connection status: $e');
    }
  }

  Future<void> _checkSSID() async {
    try {
      debugPrint('Starting Chatridge connection test...');
      // Test actual connection to ESP32 server instead of just checking SSID
      final apiService = ApiService();
      final isServerReachable = await apiService.testConnection();

      _isConnectedToChatridge = isServerReachable;
      _currentSSID = isServerReachable ? 'Chatridge' : 'Unknown';

      debugPrint('Chatridge server reachable: $isServerReachable');
      debugPrint(
          'Connection status updated - isConnectedToChatridge: $_isConnectedToChatridge');
    } catch (e) {
      debugPrint('Error checking Chatridge connection: $e');
      _isConnectedToChatridge = false;
      _currentSSID = 'Unknown';
    }
  }

  // Manual check for Chatridge connection
  Future<bool> checkChatridgeConnection() async {
    try {
      final apiService = ApiService();
      final isServerReachable = await apiService.testConnection();

      _isConnectedToChatridge = isServerReachable;
      _currentSSID = isServerReachable ? 'Chatridge' : 'Unknown';

      notifyListeners();
      return isServerReachable;
    } catch (e) {
      debugPrint('Error checking Chatridge connection: $e');
      _isConnectedToChatridge = false;
      _currentSSID = 'Unknown';
      notifyListeners();
      return false;
    }
  }

  // Force refresh connectivity status
  Future<void> refreshConnectivity() async {
    try {
      final connectivityResults = await _connectivity.checkConnectivity();
      await _updateConnectionStatus(connectivityResults);

      // Also test Chatridge connection specifically
      await _checkSSID();
    } catch (e) {
      debugPrint('Error refreshing connectivity: $e');
    }
  }

  // Get connection status text
  String getConnectionStatusText() {
    if (!_isConnected) {
      return 'No internet connection';
    } else if (_isConnectedToChatridge) {
      return 'Connected to Chatridge network';
    } else {
      return 'Connected to internet (not Chatridge)';
    }
  }

  // Get connection status color
  Color getConnectionStatusColor() {
    if (!_isConnected) {
      return Colors.red;
    } else if (_isConnectedToChatridge) {
      return Colors.green;
    } else {
      return Colors.orange;
    }
  }

  // Get connection status icon
  IconData getConnectionStatusIcon() {
    if (!_isConnected) {
      return Icons.wifi_off;
    } else if (_isConnectedToChatridge) {
      return Icons.wifi;
    } else {
      return Icons.wifi_off;
    }
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
