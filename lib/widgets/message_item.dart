import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../models/message.dart';
import '../utils/helpers.dart';
import '../screens/image_viewer_screen.dart';
import '../utils/constants.dart';

class MessageItem extends StatelessWidget {
  const MessageItem({
    super.key,
    required this.message,
    this.onTap,
  });
  final Message message;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isMe =
        message.username == 'You'; // This should be compared with current user
    final hasAttachment = message.hasAttachment;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            // Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: Helpers.getAvatarColor(message.username),
              child: Text(
                Helpers.getInitials(message.username),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message Content
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Username and timestamp
                if (!isMe) ...[
                  Text(
                    message.username,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],

                // Message bubble
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        isMe ? const Color(0xFF3498DB) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      if (message.text.isNotEmpty) ...[
                        Text(
                          message.text,
                          style: TextStyle(
                            color: isMe ? Colors.white : Colors.black87,
                            fontSize: 14,
                          ),
                        ),
                        if (hasAttachment) const SizedBox(height: 8),
                      ],

                      // Attachment
                      if (hasAttachment) ...[
                        _buildAttachment(context),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Timestamp and status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.formattedTime,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 4),
                      Icon(
                        message.isLocal ? Icons.schedule : Icons.done,
                        size: 12,
                        color: message.isLocal ? Colors.orange : Colors.green,
                      ),
                    ],
                    if (message.isPrivate) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.lock,
                        size: 12,
                        color: Colors.blue,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          if (isMe) ...[
            const SizedBox(width: 8),
            // Avatar for sent messages
            CircleAvatar(
              radius: 16,
              backgroundColor: Helpers.getAvatarColor(message.username),
              child: Text(
                Helpers.getInitials(message.username),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAttachment(BuildContext context) {
    if (message.isImage) {
      return _buildImageAttachment(context);
    } else {
      return _buildDocumentAttachment(context);
    }
  }

  Widget _buildImageAttachment(BuildContext context) {
    String resolvedUrl = message.attachmentUrl!.startsWith('http')
        ? message.attachmentUrl!
        : '${Constants.baseUrl}${message.attachmentUrl}';
    resolvedUrl = Uri.parse(resolvedUrl).toString();
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ImageViewerScreen(
              imageUrl: resolvedUrl,
              imageName: message.attachmentName,
            ),
          ),
        );
      },
      child: Container(
        constraints: const BoxConstraints(
          maxWidth: 200,
          maxHeight: 200,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            resolvedUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 100,
                color: Colors.grey.shade200,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 100,
                color: Colors.grey.shade200,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image),
                    SizedBox(height: 4),
                    Text(
                      'Failed to load',
                      style: TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentAttachment(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        try {
          final String url = message.attachmentUrl!.startsWith('http')
              ? message.attachmentUrl!
              : '${Constants.baseUrl}${message.attachmentUrl}';
          final encoded = Uri.parse(url).toString();
          // Download to temp then open
          // ignore: use_build_context_synchronously
          final tempDir = await getTemporaryDirectory();
          final savePath =
              '${tempDir.path}/${message.attachmentName ?? 'file'}';
          await Dio().download(encoded, savePath);
          await OpenFile.open(savePath);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Cannot open file: $e')),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getDocumentIcon(),
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.attachmentName ?? 'Unknown file',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Tap to open',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getDocumentIcon() {
    final fileName = message.attachmentName ?? '';
    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }
}
