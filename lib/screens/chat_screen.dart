import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/message_item.dart';
import '../widgets/device_list.dart';
import '../widgets/input_area.dart';
import 'settings_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

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
            const Text('Chatridge'),
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
          // Device List Toggle
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              setState(() {
                _showDevices = !_showDevices;
              });
            },
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
          ),
        ],
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
              height: 100,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: const DeviceList(),
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
