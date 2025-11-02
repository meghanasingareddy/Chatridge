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
          // Refresh Button
          Consumer2<ChatProvider, DeviceProvider>(
            builder: (context, chatProvider, deviceProvider, child) {
              return IconButton(
                icon: chatProvider.isLoading || deviceProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                onPressed: (chatProvider.isLoading || deviceProvider.isLoading)
                    ? null
                    : () async {
                        await chatProvider.fetchMessages();
                        await deviceProvider.fetchDevices();
                      },
                tooltip: 'Refresh conversations',
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // TODO: Add search functionality
            },
            tooltip: 'Search conversations',
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
            tooltip: 'Settings',
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
            final theme = Theme.of(context);
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: theme.colorScheme.onSurface.withOpacity(0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No conversations yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start chatting to see conversations here',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
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

                final theme = Theme.of(context);
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: unreadCount > 0 ? 2 : 0,
                  child: ListTile(
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
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        if (isPrivate)
                          Icon(
                            Icons.lock,
                            size: 16,
                            color: theme.colorScheme.primary,
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
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(lastMessage['timestamp'] as DateTime),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                    trailing: unreadCount > 0
                        ? Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
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
                  ),
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
        // Private message - determine participant based on who sent it and who it's for
        if (message.username == myUsername || message.username == myDeviceName) {
          // Message sent by me
          participant = message.target ?? message.username;
        } else if (message.target == myDeviceName || message.target == myUsername) {
          // Message sent to me
          participant = message.username;
        } else {
          // Message between others, skip if not relevant to me
          continue;
        }
        conversationKey = 'private_$participant';
      } else {
        // Group message
        conversationKey = 'group';
        participant = 'Group Chat';
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

