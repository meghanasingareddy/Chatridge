import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../core/app_export.dart';
import './widgets/connection_status_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_context_menu_widget.dart';
import './widgets/message_input_widget.dart';
import './widgets/typing_indicator_widget.dart';

class ChatInterface extends StatefulWidget {
  const ChatInterface({Key? key}) : super(key: key);

  @override
  State<ChatInterface> createState() => _ChatInterfaceState();
}

class _ChatInterfaceState extends State<ChatInterface>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isConnected = true;
  bool _isSending = false;
  bool _isReconnecting = false;
  bool _showTypingIndicator = false;
  String _connectedDeviceName = "ESP32-BlueBridge-001";
  int _signalStrength = -45;
  Map<String, dynamic>? _selectedMessage;
  bool _showContextMenu = false;

  // Mock data for demonstration
  final List<Map<String, dynamic>> _mockMessages = [
    {
      "id": "1",
      "content":
          "Hey! Are you receiving this message through the Bluetooth connection?",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 15)),
      "isCurrentUser": false,
      "status": "delivered",
      "encrypted": true,
      "sender": "Alex Chen"
    },
    {
      "id": "2",
      "content":
          "Yes! The BlueBridge connection is working perfectly. Signal strength looks good.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 14)),
      "isCurrentUser": true,
      "status": "delivered",
      "encrypted": true,
      "sender": "You"
    },
    {
      "id": "3",
      "content":
          "Great! This offline communication system is really impressive. No internet needed at all.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 12)),
      "isCurrentUser": false,
      "status": "delivered",
      "encrypted": true,
      "sender": "Alex Chen"
    },
    {
      "id": "4",
      "content":
          "Perfect for emergency situations or remote areas. The ESP32 microcontroller is handling the relay beautifully.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 10)),
      "isCurrentUser": true,
      "status": "delivered",
      "encrypted": true,
      "sender": "You"
    },
    {
      "id": "5",
      "content":
          "I'm testing the message encryption feature now. All communications should be secure.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 8)),
      "isCurrentUser": false,
      "status": "delivered",
      "encrypted": true,
      "sender": "Alex Chen"
    },
    {
      "id": "6",
      "content":
          "Encryption confirmed! The lock icon shows our messages are protected end-to-end.",
      "timestamp": DateTime.now().subtract(const Duration(minutes: 5)),
      "isCurrentUser": true,
      "status": "failed",
      "encrypted": true,
      "sender": "You"
    }
  ];

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _simulateConnectionChanges();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _loadMessages() {
    setState(() {
      _messages.addAll(_mockMessages);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _simulateConnectionChanges() {
    // Simulate typing indicator
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showTypingIndicator = true;
        });

        Future.delayed(const Duration(seconds: 4), () {
          if (mounted) {
            setState(() {
              _showTypingIndicator = false;
            });
          }
        });
      }
    });

    // Simulate connection fluctuations
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted) {
        setState(() {
          _isConnected = false;
          _isReconnecting = true;
        });

        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _isConnected = true;
              _isReconnecting = false;
              _signalStrength = -55;
            });
          }
        });
      }
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadOlderMessages();
    }
  }

  void _loadOlderMessages() {
    // Simulate loading older messages
    final olderMessages = [
      {
        "id": "old_1",
        "content": "Testing the message history loading feature...",
        "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
        "isCurrentUser": true,
        "status": "delivered",
        "encrypted": true,
        "sender": "You"
      },
      {
        "id": "old_2",
        "content": "BlueBridge connection established successfully!",
        "timestamp":
            DateTime.now().subtract(const Duration(hours: 2, minutes: 5)),
        "isCurrentUser": false,
        "status": "delivered",
        "encrypted": true,
        "sender": "Alex Chen"
      }
    ];

    setState(() {
      _messages.insertAll(0, olderMessages);
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.minScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage(String content) {
    if (content.trim().isEmpty || !_isConnected) return;

    setState(() {
      _isSending = true;
    });

    final newMessage = {
      "id": DateTime.now().millisecondsSinceEpoch.toString(),
      "content": content,
      "timestamp": DateTime.now(),
      "isCurrentUser": true,
      "status": "sending",
      "encrypted": true,
      "sender": "You"
    };

    setState(() {
      _messages.add(newMessage);
    });

    _scrollToBottom();

    // Simulate message sending
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isSending = false;
          final messageIndex =
              _messages.indexWhere((msg) => msg['id'] == newMessage['id']);
          if (messageIndex != -1) {
            _messages[messageIndex]['status'] = 'delivered';
          }
        });
      }
    });
  }

  void _retryMessage(Map<String, dynamic> message) {
    setState(() {
      message['status'] = 'sending';
    });

    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          message['status'] = 'delivered';
        });
      }
    });
  }

  void _deleteMessage(Map<String, dynamic> message) {
    setState(() {
      _messages.removeWhere((msg) => msg['id'] == message['id']);
    });
  }

  void _showMessageContextMenu(Map<String, dynamic> message) {
    setState(() {
      _selectedMessage = message;
      _showContextMenu = true;
    });
  }

  void _hideContextMenu() {
    setState(() {
      _showContextMenu = false;
      _selectedMessage = null;
    });
  }

  void _onAttachment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Attachment feature coming soon!'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          Column(
            children: [
              // App Bar with back button and connection status
              Container(
                padding:
                    EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                decoration: BoxDecoration(
                  color: AppTheme.lightTheme.colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: CustomIconWidget(
                        iconName: 'arrow_back',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 6.w,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'BlueBridge Chat',
                        style: GoogleFonts.inter(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.lightTheme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/connection-status'),
                      icon: CustomIconWidget(
                        iconName: 'settings',
                        color: AppTheme.lightTheme.colorScheme.onSurface,
                        size: 6.w,
                      ),
                    ),
                  ],
                ),
              ),

              // Connection Status Banner
              ConnectionStatusWidget(
                isConnected: _isConnected,
                deviceName: _connectedDeviceName,
                signalStrength: _signalStrength,
                isReconnecting: _isReconnecting,
              ),

              // Messages List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    _loadOlderMessages();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.symmetric(vertical: 1.h),
                    itemCount:
                        _messages.length + (_showTypingIndicator ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == 0 && _showTypingIndicator) {
                        return const TypingIndicatorWidget(
                            userName: "Alex Chen");
                      }

                      final messageIndex =
                          _showTypingIndicator ? index - 1 : index;
                      final message =
                          _messages[_messages.length - 1 - messageIndex];
                      final isCurrentUser =
                          message['isCurrentUser'] as bool? ?? false;

                      return Slidable(
                        key: Key(message['id'].toString()),
                        endActionPane: ActionPane(
                          motion: const ScrollMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (_) => _deleteMessage(message),
                              backgroundColor: AppTheme.errorLight,
                              foregroundColor: Colors.white,
                              icon: Icons.delete,
                              label: 'Delete',
                            ),
                          ],
                        ),
                        child: MessageBubbleWidget(
                          message: message,
                          isCurrentUser: isCurrentUser,
                          onLongPress: () => _showMessageContextMenu(message),
                          onRetry: message['status'] == 'failed'
                              ? () => _retryMessage(message)
                              : null,
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Message Input
              MessageInputWidget(
                onSendMessage: _sendMessage,
                onAttachment: _onAttachment,
                isConnected: _isConnected,
                isSending: _isSending,
              ),
            ],
          ),

          // Context Menu Overlay
          if (_showContextMenu && _selectedMessage != null)
            MessageContextMenuWidget(
              message: _selectedMessage!,
              onCopy: () {},
              onDelete: () => _deleteMessage(_selectedMessage!),
              onRetry: _selectedMessage!['status'] == 'failed'
                  ? () => _retryMessage(_selectedMessage!)
                  : null,
              onDismiss: _hideContextMenu,
            ),
        ],
      ),
    );
  }
}