import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/connectivity_provider.dart';
import '../providers/device_provider.dart';
import '../services/storage_service.dart';
import '../widgets/message_item.dart';
import '../widgets/device_list.dart';
import '../widgets/input_area.dart';
import 'settings_screen.dart';
import 'conversations_screen.dart';

class ChatScreen extends StatefulWidget {
  final String? initialTarget;
  
  const ChatScreen({super.key, this.initialTarget});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _selectedTarget;
  bool _showDevices = false;

  @override
  void initState() {
    super.initState();
    _selectedTarget = widget.initialTarget;
    _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onMessageSent() {
    _scrollToBottom();
  }

  void _onTargetSelected(String? target) {
    setState(() {
      _selectedTarget = target;
      _showDevices = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _selectedTarget != null 
                ? _selectedTarget! 
                : 'Group Chat',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Consumer<ConnectivityProvider>(
              builder: (context, connectivityProvider, child) {
                return Text(
                  connectivityProvider.getConnectionStatusText(),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          // WiFi Test Connection Button
          Consumer<ConnectivityProvider>(
            builder: (context, connectivityProvider, child) {
              return IconButton(
                icon: const Icon(Icons.wifi_find),
                onPressed: () async {
                  await connectivityProvider.refreshConnectivity();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          connectivityProvider.isConnectedToChatridge
                              ? 'Successfully connected to Chatridge!'
                              : 'Could not connect to Chatridge server. Please check your WiFi connection.',
                        ),
                        backgroundColor:
                            connectivityProvider.isConnectedToChatridge
                                ? Colors.green
                                : Colors.orange,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
                tooltip: 'Test WiFi Connection',
              );
            },
          ),
          // Refresh Button
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return IconButton(
                icon: chatProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: chatProvider.isLoading
                    ? null
                    : () async {
                        await chatProvider.fetchMessages();
                        await context.read<DeviceProvider>().fetchDevices();
                      },
                tooltip: 'Refresh messages',
              );
            },
          ),
          // Device List Toggle
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              setState(() {
                _showDevices = !_showDevices;
              });
            },
            tooltip: 'Show devices',
          ),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Navigate to conversations screen instead of just popping
            final username = StorageService.getUsername();
            if (username != null) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const ConversationsScreen(),
                ),
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Connection Status Bar
          Consumer<ConnectivityProvider>(
            builder: (context, connectivityProvider, child) {
              if (!connectivityProvider.isConnectedToChatridge) {
                return Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  color: Colors.orange,
                  child: const Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'Not connected to Chatridge network',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),

          // Device List
          if (_showDevices) ...[
            Container(
              height: 120,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: DeviceList(
                onDeviceSelected: _onTargetSelected,
              ),
            ),
          ],

          // Messages List
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages =
                    chatProvider.getMessagesForTarget(_selectedTarget);

                if (messages.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Start a conversation!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => chatProvider.refresh(),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return MessageItem(
                        message: message,
                        onTap: () {
                          // Handle message tap (e.g., open attachment)
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),

          // Input Area
          InputArea(
            onMessageSent: _onMessageSent,
            selectedTarget: _selectedTarget,
            onTargetSelected: _onTargetSelected,
          ),
        ],
      ),
    );
  }
}
