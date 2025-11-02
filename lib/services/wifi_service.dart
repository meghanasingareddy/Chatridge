import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/constants.dart';

// Conditional import for wifi_iot (only available on mobile)
import 'wifi_service_stub.dart'
    if (dart.library.io) 'wifi_service_mobile.dart' as wifi_impl;

class WifiService {
  factory WifiService() => _instance;
  WifiService._internal();
  static final WifiService _instance = WifiService._internal();

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
           defaultTargetPlatform == TargetPlatform.linux ||
           defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<bool> ensureConnectedToEsp() async {
    // Web cannot manage Wi‑Fi; assume manual connection
    if (kIsWeb) {
      return true;
    }

    // Desktop platforms: assume manual connection (user connects via OS WiFi settings)
    if (_isDesktop) {
      debugPrint('Desktop platform: Please connect to ${Constants.esp32SSID} manually via your OS WiFi settings');
      return true; // Assume connected, let API calls determine actual connection
    }

    // Mobile platforms: try to connect automatically using wifi_iot
    // wifi_iot may not be available on all platforms, so we catch MissingPluginException
    try {
      return await wifi_impl.connectUsingWifiIotMobile();
    } on MissingPluginException catch (e) {
      debugPrint('WiFi plugin not available on this platform: $e');
      debugPrint('Please connect to ${Constants.esp32SSID} manually');
      return true; // Assume manual connection
    } catch (e) {
      debugPrint('WiFi connect error: $e');
      return true; // Assume manual connection needed
    }
  }
}
