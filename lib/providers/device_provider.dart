import 'dart:async';
import 'package:flutter/material.dart';
import '../models/device.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../utils/constants.dart';

class DeviceProvider extends ChangeNotifier {
  DeviceProvider() {
    _loadDevicesFromStorage();
    _startPolling();
  }
  final ApiService _apiService = ApiService();

  List<Device> _devices = [];
  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  final int _pollingInterval = Constants.devicePollingInterval;

  List<Device> get devices => _devices;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get pollingInterval => _pollingInterval;

  // Load devices from local storage
  void _loadDevicesFromStorage() {
    _devices = StorageService.getDevices();
    notifyListeners();
  }

  // Start automatic polling
  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      Duration(seconds: _pollingInterval),
      (_) => fetchDevices(),
    );
  }

  // Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Fetch devices from server
  Future<void> fetchDevices() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final serverDevices = await _apiService.getDevices();

      // Update local devices with server data
      for (final serverDevice in serverDevices) {
        final existingIndex = _devices.indexWhere(
          (device) => device.name == serverDevice.name,
        );

        if (existingIndex >= 0) {
          _devices[existingIndex] = serverDevice;
        } else {
          _devices.add(serverDevice);
        }
      }

      // Remove devices that are no longer online
      _devices.removeWhere(
        (device) => !serverDevices
            .any((serverDevice) => serverDevice.name == device.name),
      );

      // Save to local storage
      for (final device in _devices) {
        await StorageService.saveDevice(device);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Get online devices
  List<Device> getOnlineDevices() {
    return _devices.where((device) => device.isOnline).toList();
  }

  // Get offline devices
  List<Device> getOfflineDevices() {
    return _devices.where((device) => !device.isOnline).toList();
  }

  // Get recently active devices
  List<Device> getRecentlyActiveDevices() {
    return _devices.where((device) => device.isRecentlyActive).toList();
  }

  // Get device by name
  Device? getDeviceByName(String name) {
    try {
      return _devices.firstWhere((device) => device.name == name);
    } catch (e) {
      return null;
    }
  }

  // Get device count
  int getDeviceCount() {
    return _devices.length;
  }

  // Get online device count
  int getOnlineDeviceCount() {
    return getOnlineDevices().length;
  }

  // Clear devices
  Future<void> clearDevices() async {
    _devices.clear();
    await StorageService.clearDevices();
    notifyListeners();
  }

  // Manual refresh
  Future<void> refresh() async {
    await fetchDevices();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get device status summary
  String getDeviceStatusSummary() {
    final onlineCount = getOnlineDeviceCount();
    final totalCount = getDeviceCount();

    if (totalCount == 0) {
      return 'No devices found';
    } else if (onlineCount == totalCount) {
      return '$onlineCount device${onlineCount == 1 ? '' : 's'} online';
    } else {
      return '$onlineCount of $totalCount devices online';
    }
  }

  // Get device status color
  Color getDeviceStatusColor() {
    final onlineCount = getOnlineDeviceCount();
    final totalCount = getDeviceCount();

    if (totalCount == 0) {
      return Colors.grey;
    } else if (onlineCount == totalCount) {
      return Colors.green;
    } else if (onlineCount > 0) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  // Get device status icon
  IconData getDeviceStatusIcon() {
    final onlineCount = getOnlineDeviceCount();
    final totalCount = getDeviceCount();

    if (totalCount == 0) {
      return Icons.device_unknown;
    } else if (onlineCount == totalCount) {
      return Icons.devices;
    } else if (onlineCount > 0) {
      return Icons.devices_other;
    } else {
      return Icons.device_unknown;
    }
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
