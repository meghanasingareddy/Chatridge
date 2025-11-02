import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/device_provider.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class ConversationsScreen extends StatelessWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Add search functionality
            },
          ),
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
      body: Consumer2<ChatProvider, DeviceProvider>(
        builder: (context, chatProvider, deviceProvider, child) {
          final messages = chatProvider.messages;
          final devices = deviceProvider.devices;

          // Get unique conversations
          final conversations = _getConversations(messages, devices);

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting to see conversations here',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await chatProvider.fetchMessages();
              await deviceProvider.fetchDevices();
            },
            child: ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final conversation = conversations[index];
                final lastMessage = conversation['lastMessage'] as Map<String, dynamic>;
                final participant = conversation['participant'] as String;
                final unreadCount = conversation['unreadCount'] as int;
                final isPrivate = conversation['isPrivate'] as bool;

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Helpers.getAvatarColor(participant),
                    child: Text(
                      Helpers.getInitials(participant),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          isPrivate ? participant : 'Group Chat',
                          style: TextStyle(
                            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isPrivate)
                        const Icon(
                          Icons.lock,
                          size: 16,
                          color: Colors.blue,
                        ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        lastMessage['text'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTime(lastMessage['timestamp'] as DateTime),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                  trailing: unreadCount > 0
                      ? Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          initialTarget: isPrivate ? participant : null,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ChatScreen(),
            ),
          );
        },
        child: const Icon(Icons.chat),
      ),
    );
  }

  List<Map<String, dynamic>> _getConversations(
    List messages,
    List devices,
  ) {
    final myUsername = StorageService.getUsername();
    final myDeviceName = StorageService.getDeviceName();
    final conversationsMap = <String, Map<String, dynamic>>{};

    // Group messages by conversation
    for (final message in messages) {
      String? conversationKey;
      String participant;

      if (message.target != null && message.target.isNotEmpty) {
        // Private message
        if (message.username == myUsername) {
          participant = message.target;
        } else {
          participant = message.username;
        }
        conversationKey = 'private_$participant';
      } else {
        // Group message
        conversationKey = 'group';
        participant = 'Group';
      }

      if (!conversationsMap.containsKey(conversationKey)) {
        conversationsMap[conversationKey] = {
          'participant': participant,
          'isPrivate': message.target != null && message.target.isNotEmpty,
          'lastMessage': {
            'text': message.hasAttachment
                ? '📎 ${message.attachmentName ?? "File"}'
                : message.text,
            'timestamp': message.timestamp,
          },
          'unreadCount': 0,
          'lastUpdate': message.timestamp,
        };
      } else {
        final conv = conversationsMap[conversationKey]!;
        if (message.timestamp.isAfter(conv['lastUpdate'] as DateTime)) {
          conv['lastMessage'] = {
            'text': message.hasAttachment
                ? '📎 ${message.attachmentName ?? "File"}'
                : message.text,
            'timestamp': message.timestamp,
          };
          conv['lastUpdate'] = message.timestamp;
        }
      }
    }

    final conversations = conversationsMap.values.toList();
    conversations.sort((a, b) {
      final aTime = a['lastUpdate'] as DateTime;
      final bTime = b['lastUpdate'] as DateTime;
      return bTime.compareTo(aTime); // Most recent first
    });

    return conversations;
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}

