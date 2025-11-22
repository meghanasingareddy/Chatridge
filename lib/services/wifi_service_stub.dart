// Stub implementation for platforms where wifi_iot is not available
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';

Future<bool> connectUsingWifiIotMobile() async {
  // This is a stub - on mobile platforms, this will be replaced
  // by an implementation that uses wifi_iot
  debugPrint('WiFi auto-connect not available on this platform');
  debugPrint('Please connect to ${Constants.esp32SSID} manually');
  return true;
}


