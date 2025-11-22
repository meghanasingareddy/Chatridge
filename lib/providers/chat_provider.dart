import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/cloud_file_service.dart';
import '../services/cloud_messaging_service.dart';
import '../utils/constants.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider() {
    _loadMessagesFromStorage();
    _loadSettings();
    _startPolling();
  }
  final ApiService _apiService = ApiService();

  List<Message> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _error;
  Timer? _pollingTimer;
  bool _autoPolling = true;
  int _pollingInterval = Constants.messagePollingInterval;

  List<Message> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get error => _error;
  bool get autoPolling => _autoPolling;
  int get pollingInterval => _pollingInterval;

  // Load messages from local storage
  void _loadMessagesFromStorage() {
    _messages = StorageService.getMessages();
    notifyListeners();
  }

  // Load settings from storage
  void _loadSettings() {
    _autoPolling = StorageService.getAutoPolling();
    _pollingInterval = StorageService.getPollingInterval();
  }

  // Start automatic polling
  void _startPolling() {
    if (_autoPolling) {
      _pollingTimer?.cancel();
      _pollingTimer = Timer.periodic(
        Duration(seconds: _pollingInterval),
        (_) => fetchMessages(),
      );
    }
  }

  // Stop polling
  void _stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  // Fetch messages from server
  Future<void> fetchMessages() async {
    if (_isLoading) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final serverMessages = await _apiService.getMessages();

      // Update local messages with server data
      // Remove local messages that might have been replaced by server messages
      // Use a more aggressive deduplication strategy
      final serverIds = serverMessages.map((m) => m.id).toSet();
      final myUsername = StorageService.getUsername();
      
      _messages.removeWhere((msg) {
        if (!msg.isLocal) return false;
        
        // Remove if we find a server message with same content and username
        return serverMessages.any((sm) => 
          sm.username == msg.username &&
          sm.text == msg.text &&
          sm.target == msg.target &&
          sm.timestamp.difference(msg.timestamp).inSeconds.abs() < 30 &&
          (msg.username == myUsername || sm.username == myUsername) // Only for messages we sent
        );
      });

      for (final serverMessage in serverMessages) {
        final existingIndex = _messages.indexWhere(
          (msg) => msg.id == serverMessage.id,
        );

        if (existingIndex >= 0) {
          _messages[existingIndex] = serverMessage;
        } else {
          _messages.add(serverMessage);
        }
      }

      // Sort messages by timestamp
      _messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));

      // Save to local storage
      for (final message in _messages) {
        await StorageService.saveMessage(message);
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String username,
    required String text,
    String? target,
  }) async {
    if (_isSending || text.trim().isEmpty) return false;

    Message? localMessage;
    try {
      _isSending = true;
      _error = null;
      notifyListeners();

      // Create local message first
      localMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        text: text.trim(),
        target: target,
        timestamp: DateTime.now(),
        isLocal: true,
      );

      _messages.add(localMessage);
      await StorageService.saveMessage(localMessage);
      notifyListeners();

      // Send to server
      final success = await _apiService.sendMessage(
        username: username,
        text: text.trim(),
        target: target,
      );

      if (success) {
        // Remove local message immediately to prevent duplicates
        _messages.removeWhere((msg) => msg.id == localMessage!.id);
        await StorageService.deleteMessage(localMessage.id);
        notifyListeners(); // Update UI immediately
        
        // Fetch messages after a short delay to get server message
        await Future.delayed(const Duration(milliseconds: 300));
        await fetchMessages();
      } else {
        // Remove failed message
        _messages.removeWhere((msg) => msg.id == localMessage!.id);
        await StorageService.deleteMessage(localMessage.id);
        _error = 'Failed to send message';
      }

      _isSending = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isSending = false;
      _error = e.toString();

      // Remove failed message if it was created
      if (localMessage != null) {
        _messages.removeWhere((msg) => msg.id == localMessage!.id);
        await StorageService.deleteMessage(localMessage.id);
      }

      notifyListeners();
      return false;
    }
  }

  // Send file
  Future<bool> sendFile({
    required String username,
    required String filePath,
    String? target,
    Function(int sent, int total)? onProgress,
  }) async {
    if (_isSending) return false;

    try {
      _isSending = true;
      _error = null;
      notifyListeners();

      debugPrint('ChatProvider: Starting file send');
      debugPrint('File path: $filePath');
      debugPrint('Username: $username, Target: $target');

      // Upload file to server
      final attachmentUrl = await _apiService.uploadFile(
        File(filePath),
        username: username,
        target: target,
        onProgress: onProgress,
      );

      debugPrint('ChatProvider: Upload result: $attachmentUrl');

      if (attachmentUrl != null) {
        // Create message with attachment
        // Normalize file path for cross-platform compatibility
        final normalizedPath = filePath.replaceAll('\\', '/');
        final fileName = normalizedPath.split('/').last;
        
        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: username,
          text: 'Shared a file',
          target: target,
          timestamp: DateTime.now(),
          attachmentUrl: attachmentUrl,
          attachmentName: fileName,
          attachmentType: _getFileType(filePath),
        );

        // Check if this is a cloud URL - if so, send message to cloud messaging service
        final isCloudUrl = CloudFileService.isCloudUrl(attachmentUrl);
        if (isCloudUrl) {
          debugPrint('ChatProvider: File uploaded to cloud, sending message to cloud service');
          try {
            // Send message with file attachment info to cloud
            final cloudMessagingService = CloudMessagingService();
            await cloudMessagingService.sendMessage(
              username: username,
              text: 'Shared a file',
              target: target,
              attachmentUrl: attachmentUrl,
              attachmentName: fileName,
              attachmentType: _getFileType(filePath),
            );
            debugPrint('ChatProvider: File message sent to cloud messaging service');
          } catch (e) {
            debugPrint('ChatProvider: Failed to send message to cloud: $e');
            // Continue anyway - message is stored locally
          }
        }

        // Remove any local message with same content to prevent duplicates
        final now = DateTime.now();
        _messages.removeWhere((msg) => 
          msg.username == username &&
          msg.text == 'Shared a file' &&
          msg.target == target &&
          msg.attachmentName == message.attachmentName &&
          msg.timestamp.difference(now).inSeconds.abs() < 10 &&
          msg.isLocal
        );
        
        _messages.add(message);
        await StorageService.saveMessage(message);
        notifyListeners(); // Update UI immediately
        debugPrint('ChatProvider: File message created and saved');
        
        // Fetch messages after a short delay to get server/cloud message with proper ID
        await Future.delayed(const Duration(milliseconds: 500));
        await fetchMessages();
      } else {
        debugPrint('ChatProvider: File upload failed - no URL returned');
      }

      _isSending = false;
      notifyListeners();
      return attachmentUrl != null;
    } catch (e) {
      _isSending = false;
      _error = e.toString();
      debugPrint('ChatProvider: File send error: $e');
      notifyListeners();
      return false;
    }
  }

  // Get messages for specific target
  List<Message> getMessagesForTarget(String? target) {
    if (target == null || target.isEmpty) {
      return _messages.where((msg) => !msg.isPrivate).toList();
    }
    // Show a 1:1 thread view: messages I sent to target, plus messages sent to me (by anyone)
    // This ensures the receiver sees private messages addressed to their device name
    final myDeviceName = StorageService.getDeviceName();
    return _messages.where((msg) {
      if (!msg.isPrivate) return false;
      final sentToPeer = msg.target == target;
      final sentToMe = myDeviceName != null && msg.target == myDeviceName;
      return sentToPeer || sentToMe;
    }).toList();
  }

  // Clear messages
  Future<void> clearMessages() async {
    _messages.clear();
    await StorageService.clearMessages();
    notifyListeners();
  }

  // Toggle auto polling
  Future<void> toggleAutoPolling() async {
    _autoPolling = !_autoPolling;
    await StorageService.setAutoPolling(_autoPolling);

    if (_autoPolling) {
      _startPolling();
    } else {
      _stopPolling();
    }

    notifyListeners();
  }

  // Set polling interval
  Future<void> setPollingInterval(int seconds) async {
    _pollingInterval = seconds;
    await StorageService.setPollingInterval(seconds);

    if (_autoPolling) {
      _startPolling();
    }

    notifyListeners();
  }

  // Manual refresh
  Future<void> refresh() async {
    await fetchMessages();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get file type from path
  String _getFileType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
      return 'image/$extension';
    }
    return 'application/$extension';
  }

  @override
  void dispose() {
    _stopPolling();
    super.dispose();
  }
}
