import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';

import 'message_service.dart';

/// BlueBridge Bluetooth Communication Service
/// 
/// This service handles Bluetooth Classic Serial Port Profile (SPP) communication
/// with ESP32 BlueBridge Hubs. It manages device discovery, connection, and
/// message relay functionality for offline mesh communication.
class BlueBridgeBluetoothService extends ChangeNotifier {
  static final BlueBridgeBluetoothService _instance = BlueBridgeBluetoothService._internal();
  factory BlueBridgeBluetoothService() => _instance;
  BlueBridgeBluetoothService._internal();

  // Services
  final MessageService _messageService = MessageService();
  
  // Connection state
  BluetoothDevice? _connectedDevice;
  BluetoothCharacteristic? _writeCharacteristic;
  BluetoothCharacteristic? _readCharacteristic;
  StreamSubscription<List<int>>? _characteristicSubscription;
  
  // Device discovery
  final List<ScanResult> _discoveredDevices = [];
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  bool _isScanning = false;
  
  // Connection status
  BluetoothConnectionState _connectionState = BluetoothConnectionState.disconnected;
  int _signalStrength = 0;
  String? _lastError;
  
  // Message buffer for incoming data
  String _messageBuffer = '';
  
  // Streams
  final StreamController<List<ScanResult>> _scanResultsController = 
      StreamController<List<ScanResult>>.broadcast();
  final StreamController<bool> _isScanningController = 
      StreamController<bool>.broadcast();
  final StreamController<BluetoothConnectionState> _connectionStateController = 
      StreamController<BluetoothConnectionState>.broadcast();
  final StreamController<String> _incomingMessageController = 
      StreamController<String>.broadcast();
  final StreamController<String> _errorController = 
      StreamController<String>.broadcast();

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  BluetoothConnectionState get connectionState => _connectionState;
  int get signalStrength => _signalStrength;
  String? get lastError => _lastError;
  bool get isConnected => _connectionState == BluetoothConnectionState.connected;
  List<ScanResult> get discoveredDevices => List.unmodifiable(_discoveredDevices);
  
  // Streams
  Stream<List<ScanResult>> get scanResults => _scanResultsController.stream;
  Stream<bool> get isScanning => _isScanningController.stream;
  Stream<BluetoothConnectionState> get connectionStateStream => _connectionStateController.stream;
  Stream<String> get incomingMessages => _incomingMessageController.stream;
  Stream<String> get errors => _errorController.stream;

  /// Initialize the Bluetooth service
  Future<bool> initialize() async {
    try {
      // Check if Bluetooth is supported
      if (await FlutterBluePlus.isSupported == false) {
        _setError('Bluetooth not supported on this device');
        return false;
      }

      // Request permissions
      if (!(await _requestPermissions())) {
        _setError('Bluetooth permissions not granted');
        return false;
      }

      // Check if Bluetooth is enabled
      final adapterState = await FlutterBluePlus.adapterState.first;
      if (adapterState != BluetoothAdapterState.on) {
        _setError('Bluetooth is not enabled');
        return false;
      }

      debugPrint('BlueBridge Bluetooth Service initialized successfully');
      return true;
    } catch (e) {
      _setError('Failed to initialize Bluetooth: $e');
      return false;
    }
  }

  /// Request necessary Bluetooth permissions
  Future<bool> _requestPermissions() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location, // Required for device discovery on Android
    ];

    final Map<Permission, PermissionStatus> statuses = 
        await permissions.request();
    
    return statuses.values.every((status) => 
        status == PermissionStatus.granted || 
        status == PermissionStatus.limited);
  }

  /// Start scanning for BlueBridge Hubs
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    try {
      if (_isScanning) {
        await stopScan();
      }

      _isScanning = true;
      _isScanningController.add(true);
      _discoveredDevices.clear();
      
      // Start BLE scan with service UUID filter for BlueBridge
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: false,
      );

      // Listen to scan results
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        _discoveredDevices.clear();
        
        // Filter for BlueBridge devices (ESP32 with BlueBridge in name)
        for (final result in results) {
          final name = result.device.platformName.toLowerCase();
          if (name.contains('bluebridge') || 
              name.contains('esp32') || 
              name.startsWith('bb_')) {
            _discoveredDevices.add(result);
          }
        }
        
        _scanResultsController.add(List.from(_discoveredDevices));
      });

      // Auto-stop scanning after timeout
      Future.delayed(timeout, () {
        if (_isScanning) {
          stopScan();
        }
      });

    } catch (e) {
      _setError('Failed to start scan: $e');
      _isScanning = false;
      _isScanningController.add(false);
    }
  }

  /// Stop scanning for devices
  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _isScanning = false;
      _isScanningController.add(false);
    } catch (e) {
      debugPrint('Error stopping scan: $e');
    }
  }

  /// Connect to a BlueBridge Hub device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _setConnectionState(BluetoothConnectionState.connecting);
      
      // Disconnect from any existing device
      if (_connectedDevice != null) {
        await disconnect(_connectedDevice!);
      }

      // Connect to the device
      await device.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      _connectedDevice = device;
      
      // Discover services
      final services = await device.discoverServices();
      
      // Look for Serial Port Profile or custom BlueBridge service
      BluetoothService? targetBleService;
      for (final service in services) {
        // Check for Serial Port Profile UUID or custom BlueBridge UUID
        if (service.serviceUuid.toString().toLowerCase().contains('1101') || // SPP UUID
            service.serviceUuid.toString().toLowerCase().contains('6e400001')) { // Nordic UART UUID
          targetBleService = service;
          break;
        }
      }

      if (targetBleService == null) {
        throw Exception('BlueBridge service not found on device');
      }

      // Get characteristics
      final characteristics = targetBleService.characteristics;
      
      for (final char in characteristics) {
        if (char.properties.write || char.properties.writeWithoutResponse) {
          _writeCharacteristic = char;
        }
        if (char.properties.read || char.properties.notify) {
          _readCharacteristic = char;
        }
      }

      if (_writeCharacteristic == null || _readCharacteristic == null) {
        throw Exception('Required characteristics not found');
      }

      // Subscribe to notifications for incoming messages
      await _readCharacteristic!.setNotifyValue(true);
      _characteristicSubscription = _readCharacteristic!.lastValueStream.listen(
        _handleIncomingData,
        onError: (error) => _setError('Characteristic read error: $error'),
      );

      _setConnectionState(BluetoothConnectionState.connected);
      _updateSignalStrength();
      
      // Register device with message service
      await _messageService.setConnectedDevice(device.platformName, device.remoteId.toString());
      
      debugPrint('Connected to BlueBridge Hub: ${device.platformName}');
      return true;

    } catch (e) {
      _setError('Connection failed: $e');
      _setConnectionState(BluetoothConnectionState.disconnected);
      _connectedDevice = null;
      return false;
    }
  }

  /// Disconnect from the current device
  Future<void> disconnect(BluetoothDevice device) async {
    try {
      _characteristicSubscription?.cancel();
      _writeCharacteristic = null;
      _readCharacteristic = null;
      
      await device.disconnect();
      
      if (_connectedDevice?.remoteId == device.remoteId) {
        _connectedDevice = null;
        _setConnectionState(BluetoothConnectionState.disconnected);
        _signalStrength = 0;
        await _messageService.clearConnectedDevice();
      }
      
      debugPrint('Disconnected from device: ${device.platformName}');
    } catch (e) {
      debugPrint('Error during disconnect: $e');
    }
  }

  /// Send a message through the BlueBridge Hub
  Future<bool> sendMessage(String content) async {
    if (!isConnected || _writeCharacteristic == null) {
      _setError('Not connected to a BlueBridge Hub');
      return false;
    }

    try {
      // Format message with BlueBridge protocol
      final message = 'MSG:$content\n';
      final bytes = utf8.encode(message);
      
      // Write to characteristic
      await _writeCharacteristic!.write(bytes, withoutResponse: false);
      
      // Store message in local history
      await _messageService.saveMessage(
        content: content,
        isOutgoing: true,
        timestamp: DateTime.now(),
        status: MessageStatus.sent,
      );
      
      debugPrint('Message sent: $content');
      return true;
      
    } catch (e) {
      _setError('Failed to send message: $e');
      
      // Mark message as failed
      await _messageService.saveMessage(
        content: content,
        isOutgoing: true,
        timestamp: DateTime.now(),
        status: MessageStatus.failed,
      );
      
      return false;
    }
  }

  /// Handle incoming data from the BlueBridge Hub
  void _handleIncomingData(List<int> data) {
    try {
      final String receivedData = utf8.decode(data);
      _messageBuffer += receivedData;
      
      // Process complete messages (delimited by \n)
      while (_messageBuffer.contains('\n')) {
        final int newlineIndex = _messageBuffer.indexOf('\n');
        final String completeMessage = _messageBuffer.substring(0, newlineIndex);
        _messageBuffer = _messageBuffer.substring(newlineIndex + 1);
        
        _processMessage(completeMessage);
      }
    } catch (e) {
      debugPrint('Error processing incoming data: $e');
    }
  }

  /// Process a complete message based on BlueBridge protocol
  void _processMessage(String message) async {
    if (message.isEmpty) return;

    try {
      if (message.startsWith('MSG:')) {
        // Chat message
        final content = message.substring(4); // Remove "MSG:" prefix
        
        // Store in message history
        await _messageService.saveMessage(
          content: content,
          isOutgoing: false,
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
        );
        
        // Notify listeners
        _incomingMessageController.add(content);
        
      } else if (message.startsWith('ALERT:')) {
        // System alert (future feature)
        debugPrint('Received alert: $message');
        
      } else if (message.startsWith('CMD:')) {
        // Command message (future feature)
        debugPrint('Received command: $message');
        
      } else {
        // Unknown message format - treat as plain text for backward compatibility
        await _messageService.saveMessage(
          content: message,
          isOutgoing: false,
          timestamp: DateTime.now(),
          status: MessageStatus.delivered,
        );
        
        _incomingMessageController.add(message);
      }
    } catch (e) {
      debugPrint('Error processing message: $e');
    }
  }

  /// Update signal strength based on RSSI
  void _updateSignalStrength() async {
    if (_connectedDevice == null) return;

    try {
      final rssi = await _connectedDevice!.readRssi();
      _signalStrength = _calculateSignalBars(rssi);
      notifyListeners();
    } catch (e) {
      debugPrint('Error reading RSSI: $e');
    }
  }

  /// Convert RSSI to signal strength bars (1-4)
  int _calculateSignalBars(int rssi) {
    if (rssi >= -60) return 4; // Excellent
    if (rssi >= -70) return 3; // Good
    if (rssi >= -80) return 2; // Fair
    return 1; // Weak
  }

  /// Set connection state and notify listeners
  void _setConnectionState(BluetoothConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
    notifyListeners();
  }

  /// Set error message and notify listeners
  void _setError(String error) {
    _lastError = error;
    _errorController.add(error);
    notifyListeners();
    debugPrint('BlueBridge Error: $error');
  }

  /// Get message history
  Future<List<Message>> getMessageHistory() async {
    return await _messageService.getMessageHistory();
  }

  /// Clear message history
  Future<void> clearMessageHistory() async {
    await _messageService.clearMessageHistory();
  }

  /// Dispose resources
  @override
  void dispose() {
    stopScan();
    _characteristicSubscription?.cancel();
    _scanResultsController.close();
    _isScanningController.close();
    _connectionStateController.close();
    _incomingMessageController.close();
    _errorController.close();
    super.dispose();
  }
}

/// Bluetooth connection states
enum BluetoothConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}