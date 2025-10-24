import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityProvider extends ChangeNotifier {
  ConnectivityProvider() {
    _initializeConnectivity();
  }
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;

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
      (ConnectivityResult result) => _updateConnectionStatus([result]),
    );

    // Check initial connectivity
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      await _updateConnectionStatus([connectivityResult]);
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
      // Note: Getting SSID programmatically is limited on newer Android versions
      // This is a simplified check - in a real app, you might need platform-specific code
      _isConnectedToChatridge = false;
      _currentSSID = 'Unknown';

      // For now, we'll assume the user is connected to Chatridge if they have internet
      // In a real implementation, you'd need to check the actual SSID
      // This is a limitation of the current approach
    } catch (e) {
      debugPrint('Error checking SSID: $e');
    }
  }

  // Manual check for Chatridge connection
  Future<bool> checkChatridgeConnection() async {
    try {
      // This would typically involve checking the network configuration
      // For now, we'll return false and let the user manually connect
      return false;
    } catch (e) {
      debugPrint('Error checking Chatridge connection: $e');
      return false;
    }
  }

  // Force refresh connectivity status
  Future<void> refreshConnectivity() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      await _updateConnectionStatus([connectivityResult]);
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
