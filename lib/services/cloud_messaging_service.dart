import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/message.dart';
import '../models/device.dart';

/// Hidden cloud messaging service for normal internet connectivity
/// This service works automatically when ESP32 is unavailable
/// Uses a simple cloud storage for messages (completely transparent)
class CloudMessagingService {
  factory CloudMessagingService() => _instance;
  CloudMessagingService._internal();
  static final CloudMessagingService _instance = CloudMessagingService._internal();

  late Dio _dio;
  bool _isInitialized = false;
  
  // Using a simple public JSON storage service
  // Messages are stored in a shared location accessible via HTTP
  static const String _storageBaseUrl = 'https://jsonbin.org';
  static const String _messagesBinId = 'chatridge-messages';
  static const String _devicesBinId = 'chatridge-devices';
  
  // Local cache for messages (to reduce API calls)
  List<Message> _cachedMessages = [];
  DateTime? _lastFetch;
  static const Duration _cacheTimeout = Duration(seconds: 2);
  
  void _initialize() {
    if (_isInitialized) return;
    
    _dio = Dio(
      BaseOptions(
        baseUrl: _storageBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
        },
      ),
    );
    
    _isInitialized = true;
  }

  /// Get all messages from cloud
  Future<List<Message>> getMessages() async {
    try {
      _initialize();
      
      // Use cache if recent
      if (_lastFetch != null && 
          DateTime.now().difference(_lastFetch!) < _cacheTimeout &&
          _cachedMessages.isNotEmpty) {
        return _cachedMessages;
      }
      
      debugPrint('CloudMessagingService: Fetching messages from cloud');
      
      final response = await _dio.get('/$_messagesBinId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<Message> messages = [];
        
        if (data is Map) {
          if (data.containsKey('messages')) {
            final List<dynamic> messagesJson = data['messages'] ?? [];
            messages = messagesJson.map((json) => Message.fromJson(json)).toList();
          } else if (data.containsKey('data') && data['data'] is Map) {
            final messagesData = data['data'];
            if (messagesData.containsKey('messages')) {
              final List<dynamic> messagesJson = messagesData['messages'] ?? [];
              messages = messagesJson.map((json) => Message.fromJson(json)).toList();
            }
          }
        } else if (data is List) {
          messages = data.map((json) => Message.fromJson(json)).toList();
        }
        
        // Update cache
        _cachedMessages = messages;
        _lastFetch = DateTime.now();
        
        return messages;
      }
      return _cachedMessages;
    } catch (e) {
      debugPrint('CloudMessagingService: Error fetching messages: $e');
      // Return cached messages if available
      return _cachedMessages;
    }
  }

  /// Send message to cloud
  Future<bool> sendMessage({
    required String username,
    required String text,
    String? target,
    String? attachmentUrl,
    String? attachmentName,
    String? attachmentType,
  }) async {
    try {
      _initialize();
      
      debugPrint('CloudMessagingService: Sending message to cloud');
      
      // Get existing messages
      final existingMessages = await getMessages();
      
      // Create new message
      final newMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        text: text,
        target: target,
        timestamp: DateTime.now(),
        attachmentUrl: attachmentUrl,
        attachmentName: attachmentName,
        attachmentType: attachmentType,
      );
      
      // Add to list (keep last 200 messages)
      final updatedMessages = [...existingMessages, newMessage];
      if (updatedMessages.length > 200) {
        updatedMessages.removeRange(0, updatedMessages.length - 200);
      }
      
      // Convert to JSON
      final messagesJson = updatedMessages.map((m) => m.toJson()).toList();
      
      // Save to cloud - try PUT first
      try {
        final response = await _dio.put(
          '/$_messagesBinId',
          data: {'messages': messagesJson},
        );
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          // Update cache
          _cachedMessages = updatedMessages;
          _lastFetch = DateTime.now();
          return true;
        }
      } catch (e) {
        debugPrint('CloudMessagingService: PUT failed, trying POST: $e');
      }
      
      // Try POST as fallback
      final response = await _dio.post(
        '/$_messagesBinId',
        data: {'messages': messagesJson},
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        _cachedMessages = updatedMessages;
        _lastFetch = DateTime.now();
        return true;
      }
      
      return false;
    } catch (e) {
      debugPrint('CloudMessagingService: Error sending message: $e');
      return false;
    }
  }

  /// Get devices from cloud
  Future<List<Device>> getDevices() async {
    try {
      _initialize();
      
      final response = await _dio.get('/$_devicesBinId');
      
      if (response.statusCode == 200) {
        final data = response.data;
        List<Device> devices = [];
        
        if (data is Map) {
          if (data.containsKey('devices')) {
            final List<dynamic> devicesJson = data['devices'] ?? [];
            devices = devicesJson.map((json) => Device.fromJson(json)).toList();
          } else if (data.containsKey('data') && data['data'] is Map) {
            final devicesData = data['data'];
            if (devicesData.containsKey('devices')) {
              final List<dynamic> devicesJson = devicesData['devices'] ?? [];
              devices = devicesJson.map((json) => Device.fromJson(json)).toList();
            }
          }
        } else if (data is List) {
          devices = data.map((json) => Device.fromJson(json)).toList();
        }
        
        return devices;
      }
      return [];
    } catch (e) {
      debugPrint('CloudMessagingService: Error fetching devices: $e');
      return [];
    }
  }

  /// Register device in cloud
  Future<bool> registerDevice(String name) async {
    try {
      _initialize();
      
      // Get existing devices
      final existingDevices = await getDevices();
      
      // Check if device already exists
      final existingIndex = existingDevices.indexWhere((d) => d.name == name);
      final now = DateTime.now();
      
      Device device;
      if (existingIndex >= 0) {
        // Update existing device
        final existing = existingDevices[existingIndex];
        device = Device(
          name: existing.name,
          ip: existing.ip,
          lastSeen: now,
          online: true,
        );
        existingDevices[existingIndex] = device;
      } else {
        // Add new device
        device = Device(
          name: name,
          ip: 'cloud',
          lastSeen: now,
          online: true,
        );
        existingDevices.add(device);
      }
      
      // Keep only last 50 devices
      if (existingDevices.length > 50) {
        existingDevices.removeRange(0, existingDevices.length - 50);
      }
      
      // Save to cloud
      final devicesJson = existingDevices.map((d) => d.toJson()).toList();
      
      try {
        final response = await _dio.put(
          '/$_devicesBinId',
          data: {'devices': devicesJson},
        );
        return response.statusCode == 200 || response.statusCode == 201;
      } catch (e) {
        // Try POST as fallback
        final response = await _dio.post(
          '/$_devicesBinId',
          data: {'devices': devicesJson},
        );
        return response.statusCode == 200 || response.statusCode == 201;
      }
    } catch (e) {
      debugPrint('CloudMessagingService: Error registering device: $e');
      return false;
    }
  }
}

