import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
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
        // Update message as sent
        localMessage.isLocal = false;
        await StorageService.saveMessage(localMessage);
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
        final message = Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          username: username,
          text: 'Shared a file',
          target: target,
          timestamp: DateTime.now(),
          attachmentUrl: attachmentUrl,
          attachmentName: filePath.split('/').last,
          attachmentType: _getFileType(filePath),
        );

        _messages.add(message);
        await StorageService.saveMessage(message);
        debugPrint('ChatProvider: File message created and saved');
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
    return _messages.where((msg) => msg.target == target).toList();
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
