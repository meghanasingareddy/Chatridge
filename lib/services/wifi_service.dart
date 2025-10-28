import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wifi_iot/wifi_iot.dart';
import '../utils/constants.dart';

class WifiService {
  WifiService._internal();
  static final WifiService _instance = WifiService._internal();
  factory WifiService() => _instance;

  Future<bool> ensureConnectedToEsp() async {
    if (kIsWeb)
      return true; // Web cannot manage Wi‑Fi; assume manual connection

    try {
      final isEnabled = await WiFiForIoTPlugin.isEnabled();
      if (isEnabled == false) {
        await WiFiForIoTPlugin.setEnabled(true);
      }

      final currentSSID = await WiFiForIoTPlugin.getSSID();
      if (currentSSID == Constants.esp32SSID) {
        return true;
      }

      final didConnect = await WiFiForIoTPlugin.connect(
        Constants.esp32SSID,
        password: Constants.esp32Password,
        security: NetworkSecurity.WPA,
        joinOnce: true,
        withInternet: false,
        isHidden: false,
      );

      if (!didConnect) return false;

      // Wait until associated
      for (int i = 0; i < 15; i++) {
        await Future.delayed(const Duration(seconds: 1));
        final ssid = await WiFiForIoTPlugin.getSSID();
        if (ssid == Constants.esp32SSID) return true;
      }

      return false;
    } catch (e) {
      debugPrint('WiFi connect error: $e');
      return false;
    }
  }
}
