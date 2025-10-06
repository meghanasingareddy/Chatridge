import 'package:flutter/material.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/device_discovery/device_discovery.dart';
import '../presentation/connection_status/connection_status.dart';
import '../presentation/chat_interface/chat_interface.dart';
import '../presentation/chat_interface/bluebridge_chat_interface.dart';
import '../presentation/message_history/message_history.dart';
import '../presentation/bluetooth_permissions/bluetooth_permissions.dart';

class AppRoutes {
  // TODO: Add your routes here
  static const String initial = '/';
  static const String splash = '/splash-screen';
  static const String deviceDiscovery = '/device-discovery';
  static const String connectionStatus = '/connection-status';
  static const String chatInterface = '/chat-interface';
  static const String bluebridgeChat = '/bluebridge-chat';
  static const String messageHistory = '/message-history';
  static const String bluetoothPermissions = '/bluetooth-permissions';
  static const String connectedDevices = '/connected-devices';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splash: (context) => const SplashScreen(),
    deviceDiscovery: (context) => const DeviceDiscovery(),
    connectionStatus: (context) => const ConnectionStatus(),
    chatInterface: (context) => const ChatInterface(),
    bluebridgeChat: (context) => const BlueBridgeChatInterface(),
    messageHistory: (context) => const MessageHistory(),
    bluetoothPermissions: (context) => const BluetoothPermissions(),
    // TODO: Add your other routes here
  };
}
