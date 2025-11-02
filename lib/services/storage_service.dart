import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/message.dart';
import '../models/device.dart';
import '../utils/constants.dart';

class StorageService {
  static late SharedPreferences _prefs;
  static late Box<Message> _messageBox;
  static late Box<Device> _deviceBox;

  static Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();

    // Register Hive adapters
    Hive.registerAdapter(MessageAdapter());
    Hive.registerAdapter(DeviceAdapter());

    // Open Hive boxes
    _messageBox = await Hive.openBox<Message>('messages');
    _deviceBox = await Hive.openBox<Device>('devices');
  }

  // Username operations
  static Future<void> saveUsername(String username) async {
    await _prefs.setString(Constants.usernameKey, username);
  }

  static String? getUsername() {
    return _prefs.getString(Constants.usernameKey);
  }

  static Future<void> clearUsername() async {
    await _prefs.remove(Constants.usernameKey);
  }

  // Device name operations
  static Future<void> saveDeviceName(String deviceName) async {
    await _prefs.setString(Constants.deviceNameKey, deviceName);
  }

  static String? getDeviceName() {
    return _prefs.getString(Constants.deviceNameKey);
  }

  static Future<void> clearDeviceName() async {
    await _prefs.remove(Constants.deviceNameKey);
  }

  // Auto polling settings
  static Future<void> setAutoPolling(bool enabled) async {
    await _prefs.setBool(Constants.autoPollingKey, enabled);
  }

  static bool getAutoPolling() {
    return _prefs.getBool(Constants.autoPollingKey) ?? true;
  }

  // Polling interval settings
  static Future<void> setPollingInterval(int seconds) async {
    await _prefs.setInt(Constants.pollingIntervalKey, seconds);
  }

  static int getPollingInterval() {
    return _prefs.getInt(Constants.pollingIntervalKey) ??
        Constants.messagePollingInterval;
  }

  // Message operations
  static Future<void> saveMessage(Message message) async {
    await _messageBox.put(message.id, message);
  }

  static List<Message> getMessages() {
    return _messageBox.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  static List<Message> getMessagesForTarget(String? target) {
    if (target == null || target.isEmpty) {
      return getMessages().where((msg) => !msg.isPrivate).toList();
    }
    return getMessages().where((msg) => msg.target == target).toList();
  }

  static Future<void> clearMessages() async {
    await _messageBox.clear();
  }

  static Future<void> deleteMessage(String messageId) async {
    await _messageBox.delete(messageId);
  }

  // Device operations
  static Future<void> saveDevice(Device device) async {
    await _deviceBox.put(device.name, device);
  }

  static List<Device> getDevices() {
    return _deviceBox.values.toList();
  }

  static Future<void> clearDevices() async {
    await _deviceBox.clear();
  }

  // Clear all data
  static Future<void> clearAllData() async {
    await clearUsername();
    await clearDeviceName();
    await clearMessages();
    await clearDevices();
  }

  // Check if user is registered
  static bool isUserRegistered() {
    return getUsername() != null && getDeviceName() != null;
  }

  // Get user info
  static Map<String, String?> getUserInfo() {
    return {
      'username': getUsername(),
      'deviceName': getDeviceName(),
    };
  }

  // Save user info
  static Future<void> saveUserInfo(String username, String deviceName) async {
    await saveUsername(username);
    await saveDeviceName(deviceName);
  }

  // Get storage info
  static Map<String, int> getStorageInfo() {
    return {
      'messageCount': _messageBox.length,
      'deviceCount': _deviceBox.length,
    };
  }

  // Theme mode operations
  static const String themeModeKey = 'theme_mode';

  static Future<void> saveThemeMode(ThemeMode mode) async {
    await _prefs.setString(themeModeKey, mode.toString());
  }

  static ThemeMode? getThemeMode() {
    final modeString = _prefs.getString(themeModeKey);
    if (modeString == null) return null;
    
    switch (modeString) {
      case 'ThemeMode.dark':
        return ThemeMode.dark;
      case 'ThemeMode.light':
        return ThemeMode.light;
      case 'ThemeMode.system':
      default:
        return ThemeMode.system;
    }
  }
}
