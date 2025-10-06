import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Message status enumeration
enum MessageStatus {
  sending,
  sent,
  delivered,
  failed,
  read,
}

/// Message model class
class Message {
  final String id;
  final String content;
  final DateTime timestamp;
  final bool isOutgoing;
  final MessageStatus status;
  final String? sender;
  final bool isEncrypted;

  const Message({
    required this.id,
    required this.content,
    required this.timestamp,
    required this.isOutgoing,
    required this.status,
    this.sender,
    this.isEncrypted = false,
  });

  /// Convert Message to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isOutgoing': isOutgoing,
      'status': status.name,
      'sender': sender,
      'isEncrypted': isEncrypted,
    };
  }

  /// Create Message from JSON
  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      content: json['content'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
      isOutgoing: json['isOutgoing'] as bool,
      status: MessageStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MessageStatus.delivered,
      ),
      sender: json['sender'] as String?,
      isEncrypted: json['isEncrypted'] as bool? ?? false,
    );
  }

  /// Create a copy of this Message with updated fields
  Message copyWith({
    String? id,
    String? content,
    DateTime? timestamp,
    bool? isOutgoing,
    MessageStatus? status,
    String? sender,
    bool? isEncrypted,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      isOutgoing: isOutgoing ?? this.isOutgoing,
      status: status ?? this.status,
      sender: sender ?? this.sender,
      isEncrypted: isEncrypted ?? this.isEncrypted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Message && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Message{id: $id, content: $content, timestamp: $timestamp, '
           'isOutgoing: $isOutgoing, status: $status, sender: $sender, '
           'isEncrypted: $isEncrypted}';
  }
}

/// Connected Device information
class ConnectedDevice {
  final String name;
  final String address;
  final DateTime connectedAt;
  final int signalStrength;

  const ConnectedDevice({
    required this.name,
    required this.address,
    required this.connectedAt,
    required this.signalStrength,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'address': address,
      'connectedAt': connectedAt.millisecondsSinceEpoch,
      'signalStrength': signalStrength,
    };
  }

  factory ConnectedDevice.fromJson(Map<String, dynamic> json) {
    return ConnectedDevice(
      name: json['name'] as String,
      address: json['address'] as String,
      connectedAt: DateTime.fromMillisecondsSinceEpoch(json['connectedAt'] as int),
      signalStrength: json['signalStrength'] as int,
    );
  }
}

/// Message Service
/// 
/// This service handles message storage, retrieval, and management for the
/// BlueBridge offline communication system. It provides persistent storage
/// using SharedPreferences and manages message history, device connections,
/// and chat sessions.
class MessageService extends ChangeNotifier {
  static final MessageService _instance = MessageService._internal();
  factory MessageService() => _instance;
  MessageService._internal();

  // Storage keys
  static const String _messagesKey = 'bluebridge_messages';
  static const String _connectedDeviceKey = 'bluebridge_connected_device';
  static const String _chatSessionKey = 'bluebridge_chat_session';
  
  // In-memory cache
  final List<Message> _messages = [];
  ConnectedDevice? _connectedDevice;
  String? _currentChatSessionId;
  
  // Streams
  final StreamController<List<Message>> _messagesController = 
      StreamController<List<Message>>.broadcast();
  final StreamController<Message> _newMessageController = 
      StreamController<Message>.broadcast();
  
  // Getters
  List<Message> get messages => List.unmodifiable(_messages);
  ConnectedDevice? get connectedDevice => _connectedDevice;
  String? get currentChatSessionId => _currentChatSessionId;
  
  // Streams
  Stream<List<Message>> get messagesStream => _messagesController.stream;
  Stream<Message> get newMessageStream => _newMessageController.stream;

  /// Initialize the message service
  Future<void> initialize() async {
    await _loadMessages();
    await _loadConnectedDevice();
    await _loadChatSession();
    debugPrint('MessageService initialized with ${_messages.length} messages');
  }

  /// Save a new message
  Future<void> saveMessage({
    required String content,
    required bool isOutgoing,
    required DateTime timestamp,
    required MessageStatus status,
    String? sender,
    bool isEncrypted = false,
  }) async {
    final message = Message(
      id: _generateMessageId(),
      content: content,
      timestamp: timestamp,
      isOutgoing: isOutgoing,
      status: status,
      sender: sender ?? (isOutgoing ? 'You' : _connectedDevice?.name ?? 'Unknown'),
      isEncrypted: isEncrypted,
    );

    _messages.add(message);
    await _saveMessages();
    
    _messagesController.add(List.from(_messages));
    _newMessageController.add(message);
    
    notifyListeners();
  }

  /// Update message status
  Future<void> updateMessageStatus(String messageId, MessageStatus status) async {
    final index = _messages.indexWhere((msg) => msg.id == messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(status: status);
      await _saveMessages();
      _messagesController.add(List.from(_messages));
      notifyListeners();
    }
  }

  /// Delete a message
  Future<void> deleteMessage(String messageId) async {
    _messages.removeWhere((msg) => msg.id == messageId);
    await _saveMessages();
    _messagesController.add(List.from(_messages));
    notifyListeners();
  }

  /// Get message history
  Future<List<Message>> getMessageHistory({
    int? limit,
    DateTime? before,
    DateTime? after,
  }) async {
    List<Message> filteredMessages = List.from(_messages);
    
    // Apply date filters
    if (before != null) {
      filteredMessages = filteredMessages
          .where((msg) => msg.timestamp.isBefore(before))
          .toList();
    }
    
    if (after != null) {
      filteredMessages = filteredMessages
          .where((msg) => msg.timestamp.isAfter(after))
          .toList();
    }
    
    // Sort by timestamp (newest first)
    filteredMessages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    // Apply limit
    if (limit != null && limit > 0) {
      filteredMessages = filteredMessages.take(limit).toList();
    }
    
    return filteredMessages;
  }

  /// Clear all messages
  Future<void> clearMessageHistory() async {
    _messages.clear();
    await _saveMessages();
    _messagesController.add(List.from(_messages));
    notifyListeners();
  }

  /// Set connected device information
  Future<void> setConnectedDevice(String name, String address) async {
    _connectedDevice = ConnectedDevice(
      name: name,
      address: address,
      connectedAt: DateTime.now(),
      signalStrength: 0,
    );
    
    await _saveConnectedDevice();
    
    // Start new chat session
    _currentChatSessionId = _generateSessionId();
    await _saveChatSession();
    
    notifyListeners();
  }

  /// Clear connected device information
  Future<void> clearConnectedDevice() async {
    _connectedDevice = null;
    _currentChatSessionId = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_connectedDeviceKey);
    await prefs.remove(_chatSessionKey);
    
    notifyListeners();
  }

  /// Get messages for current chat session
  List<Message> getCurrentSessionMessages() {
    if (_currentChatSessionId == null) return [];
    
    // For now, return all messages. In future, filter by session ID
    return List.from(_messages);
  }

  /// Search messages by content
  List<Message> searchMessages(String query) {
    if (query.isEmpty) return List.from(_messages);
    
    final lowercaseQuery = query.toLowerCase();
    return _messages
        .where((msg) => msg.content.toLowerCase().contains(lowercaseQuery))
        .toList();
  }

  /// Get message statistics
  Map<String, int> getMessageStats() {
    final totalMessages = _messages.length;
    final sentMessages = _messages.where((msg) => msg.isOutgoing).length;
    final receivedMessages = _messages.where((msg) => !msg.isOutgoing).length;
    final failedMessages = _messages
        .where((msg) => msg.status == MessageStatus.failed)
        .length;
    
    return {
      'total': totalMessages,
      'sent': sentMessages,
      'received': receivedMessages,
      'failed': failedMessages,
    };
  }

  /// Load messages from storage
  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = prefs.getString(_messagesKey);
      
      if (messagesJson != null) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        _messages.clear();
        _messages.addAll(
          messagesList.map((json) => Message.fromJson(json)).toList(),
        );
        
        // Sort messages by timestamp
        _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
    }
  }

  /// Save messages to storage
  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesJson = json.encode(
        _messages.map((msg) => msg.toJson()).toList(),
      );
      await prefs.setString(_messagesKey, messagesJson);
    } catch (e) {
      debugPrint('Error saving messages: $e');
    }
  }

  /// Load connected device from storage
  Future<void> _loadConnectedDevice() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final deviceJson = prefs.getString(_connectedDeviceKey);
      
      if (deviceJson != null) {
        final deviceMap = json.decode(deviceJson) as Map<String, dynamic>;
        _connectedDevice = ConnectedDevice.fromJson(deviceMap);
      }
    } catch (e) {
      debugPrint('Error loading connected device: $e');
    }
  }

  /// Save connected device to storage
  Future<void> _saveConnectedDevice() async {
    try {
      if (_connectedDevice == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      final deviceJson = json.encode(_connectedDevice!.toJson());
      await prefs.setString(_connectedDeviceKey, deviceJson);
    } catch (e) {
      debugPrint('Error saving connected device: $e');
    }
  }

  /// Load chat session from storage
  Future<void> _loadChatSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _currentChatSessionId = prefs.getString(_chatSessionKey);
    } catch (e) {
      debugPrint('Error loading chat session: $e');
    }
  }

  /// Save chat session to storage
  Future<void> _saveChatSession() async {
    try {
      if (_currentChatSessionId == null) return;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_chatSessionKey, _currentChatSessionId!);
    } catch (e) {
      debugPrint('Error saving chat session: $e');
    }
  }

  /// Generate unique message ID
  String _generateMessageId() {
    return '${DateTime.now().millisecondsSinceEpoch}_${_messages.length}';
  }

  /// Generate unique session ID
  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Dispose resources
  @override
  void dispose() {
    _messagesController.close();
    _newMessageController.close();
    super.dispose();
  }
}