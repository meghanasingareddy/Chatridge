import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import '../../core/app_export.dart';
import '../../services/bluetooth_service.dart';
import '../../services/message_service.dart';
import './widgets/connection_status_widget.dart';
import './widgets/message_bubble_widget.dart';
import './widgets/message_context_menu_widget.dart';
import './widgets/typing_indicator_widget.dart';

class BlueBridgeChatInterface extends StatefulWidget {
  const BlueBridgeChatInterface({Key? key}) : super(key: key);

  @override
  State<BlueBridgeChatInterface> createState() => _BlueBridgeChatInterfaceState();
}

class _BlueBridgeChatInterfaceState extends State<BlueBridgeChatInterface>
    with TickerProviderStateMixin {
  
  // Services
  final BlueBridgeBluetoothService _bluetoothService = BlueBridgeBluetoothService();
  final MessageService _messageService = MessageService();
  
  // UI Controllers
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _messageController = TextEditingController();
  
  // State variables
  List<Message> _messages = [];
  bool _isSending = false;
  bool _showTypingIndicator = false;
  Map<String, dynamic>? _selectedMessage;
  bool _showContextMenu = false;
  
  // Subscriptions
  StreamSubscription<String>? _incomingMessageSubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;
  StreamSubscription<String>? _errorSubscription;
  StreamSubscription<List<Message>>? _messagesSubscription;

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _setupListeners();
    _loadMessages();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _messageController.dispose();
    _incomingMessageSubscription?.cancel();
    _connectionStateSubscription?.cancel();
    _errorSubscription?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    await _messageService.initialize();
    await _bluetoothService.initialize();
  }

  void _setupListeners() {
    // Listen for incoming messages
    _incomingMessageSubscription = _bluetoothService.incomingMessages.listen(
      (message) {
        _scrollToBottom();
        setState(() {
          _showTypingIndicator = false;
        });
      },
    );

    // Listen for connection state changes
    _connectionStateSubscription = _bluetoothService.connectionStateStream.listen(
      (state) {
        setState(() {});
        
        if (state == BluetoothConnectionState.connected) {
          _showConnectionSuccess();
        } else if (state == BluetoothConnectionState.disconnected) {
          _showConnectionLost();
        }
      },
    );

    // Listen for errors
    _errorSubscription = _bluetoothService.errors.listen(
      (error) {
        _showError(error);
      },
    );

    // Listen for message updates
    _messagesSubscription = _messageService.messagesStream.listen(
      (messages) {
        setState(() {
          _messages = messages;
        });
        _scrollToBottom();
      },
    );
  }

  Future<void> _loadMessages() async {
    final messages = await _messageService.getMessageHistory();
    setState(() {
      _messages = messages;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      _loadOlderMessages();
    }
  }

  void _loadOlderMessages() {
    // Load more messages from history
    // This would implement pagination in a real app
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || !_bluetoothService.isConnected) return;

    setState(() {
      _isSending = true;
    });

    _messageController.clear();
    
    final success = await _bluetoothService.sendMessage(content);
    
    setState(() {
      _isSending = false;
    });

    if (!success) {
      _showError('Failed to send message');
    }
  }

  void _retryMessage(Message message) async {
    final success = await _bluetoothService.sendMessage(message.content);
    
    if (success) {
      await _messageService.updateMessageStatus(
        message.id, 
        MessageStatus.sent,
      );
    }
  }

  void _deleteMessage(Message message) async {
    await _messageService.deleteMessage(message.id);
  }

  void _showMessageContextMenu(Message message) {
    setState(() {
      _selectedMessage = {
        'id': message.id,
        'content': message.content,
        'status': message.status.name,
      };
      _showContextMenu = true;
    });
  }

  void _hideContextMenu() {
    setState(() {
      _showContextMenu = false;
      _selectedMessage = null;
    });
  }

  void _showConnectionSuccess() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 5.w),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Connected to ${_bluetoothService.connectedDevice?.platformName ?? "BlueBridge Hub"}',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showConnectionLost() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white, size: 5.w),
            SizedBox(width: 2.w),
            Text(
              'Connection lost',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Reconnect',
          textColor: Colors.white,
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/device-discovery');
          },
        ),
      ),
    );
  }

  void _showError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
              // App Bar
              _buildAppBar(),
              
              // Connection Status
              _buildConnectionStatus(),
              
              // Messages List
              Expanded(
                child: _buildMessagesList(),
              ),
              
              // Message Input
              _buildMessageInput(),
            ],
          ),

          // Context Menu Overlay
          if (_showContextMenu && _selectedMessage != null)
            _buildContextMenuOverlay(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 4.w,
        right: 4.w,
        bottom: 2.h,
      ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'BlueBridge Chat',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.lightTheme.colorScheme.onSurface,
                  ),
                ),
                if (_bluetoothService.connectedDevice != null)
                  Text(
                    _bluetoothService.connectedDevice!.platformName,
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: AppTheme.lightTheme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/connection-status'),
            icon: CustomIconWidget(
              iconName: 'settings',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return ConnectionStatusWidget(
      isConnected: _bluetoothService.isConnected,
      deviceName: _bluetoothService.connectedDevice?.platformName ?? '',
      signalStrength: _bluetoothService.signalStrength,
      isReconnecting: _bluetoothService.connectionState == BluetoothConnectionState.reconnecting,
    );
  }

  Widget _buildMessagesList() {
    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: EdgeInsets.symmetric(vertical: 1.h),
        itemCount: _messages.length + (_showTypingIndicator ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == 0 && _showTypingIndicator) {
            return TypingIndicatorWidget(
              userName: _bluetoothService.connectedDevice?.platformName ?? "Someone",
            );
          }

          final messageIndex = _showTypingIndicator ? index - 1 : index;
          final message = _messages[_messages.length - 1 - messageIndex];
          
          // Convert Message to Map for compatibility with existing widgets
          final messageMap = {
            'id': message.id,
            'content': message.content,
            'timestamp': message.timestamp,
            'isCurrentUser': message.isOutgoing,
            'status': message.status.name,
            'encrypted': message.isEncrypted,
            'sender': message.sender ?? (message.isOutgoing ? 'You' : 'Unknown'),
          };

          return Slidable(
            key: Key(message.id),
            endActionPane: ActionPane(
              motion: const ScrollMotion(),
              children: [
                SlidableAction(
                  onPressed: (_) => _deleteMessage(message),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  icon: Icons.delete,
                  label: 'Delete',
                ),
              ],
            ),
            child: MessageBubbleWidget(
              message: messageMap,
              isCurrentUser: message.isOutgoing,
              onLongPress: () => _showMessageContextMenu(message),
              onRetry: message.status == MessageStatus.failed
                  ? () => _retryMessage(message)
                  : null,
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: _bluetoothService.isConnected 
                    ? 'Type a message...' 
                    : 'Not connected to BlueBridge Hub',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppTheme.lightTheme.colorScheme.surface,
                contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              ),
              enabled: _bluetoothService.isConnected && !_isSending,
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
            ),
          ),
          SizedBox(width: 2.w),
          FloatingActionButton(
            onPressed: _bluetoothService.isConnected && !_isSending ? _sendMessage : null,
            mini: true,
            backgroundColor: _bluetoothService.isConnected && !_isSending 
                ? AppTheme.lightTheme.primaryColor
                : Colors.grey,
            child: _isSending
                ? SizedBox(
                    width: 4.w,
                    height: 4.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(Icons.send, color: Colors.white, size: 5.w),
          ),
        ],
      ),
    );
  }

  Widget _buildContextMenuOverlay() {
    return MessageContextMenuWidget(
      message: _selectedMessage!,
      onCopy: () {
        // Implement copy functionality
        _hideContextMenu();
      },
      onDelete: () {
        final messageId = _selectedMessage!['id'] as String;
        final message = _messages.firstWhere((m) => m.id == messageId);
        _deleteMessage(message);
        _hideContextMenu();
      },
      onRetry: _selectedMessage!['status'] == 'failed'
          ? () {
              final messageId = _selectedMessage!['id'] as String;
              final message = _messages.firstWhere((m) => m.id == messageId);
              _retryMessage(message);
              _hideContextMenu();
            }
          : null,
      onDismiss: _hideContextMenu,
    );
  }
}