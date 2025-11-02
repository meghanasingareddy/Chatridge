import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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

  String _resolvedUrl() {
    if (!message.hasAttachment) return '';
    final raw = message.attachmentUrl!;
    // Return just the path, not full URL (Dio will use baseUrl)
    return raw.startsWith('http') ? raw.replaceFirst(RegExp(r'^https?://[^/]+'), '') : raw;
  }
  
  String _getFullUrl() {
    if (!message.hasAttachment) return '';
    final raw = message.attachmentUrl!;
    if (raw.startsWith('http')) return raw;
    return '${Constants.baseUrl}${raw.startsWith('/') ? raw : '/$raw'}';
  }

  Future<void> _downloadAttachment(BuildContext context) async {
    try {
      final filePath = _resolvedUrl();
      if (filePath.isEmpty) throw Exception('Missing file path');
      
      // Create properly configured Dio instance with baseUrl
      final dio = Dio(BaseOptions(
        baseUrl: Constants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      ));
      
      final dir = await getApplicationDocumentsDirectory();
      final filename = message.attachmentName ?? 'file';
      final savePath = '${dir.path}/$filename';
      
      // Ensure path starts with /
      String path = filePath.startsWith('/') ? filePath : '/$filePath';
      debugPrint('Downloading file: ${Constants.baseUrl}$path');
      
      await dio.download(path, savePath);
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved to $savePath')),
      );
    } catch (e) {
      debugPrint('Download error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Download failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _shareAttachment(BuildContext context) async {
    try {
      final filePath = _resolvedUrl();
      if (filePath.isEmpty) throw Exception('Missing file path');
      
      // Create properly configured Dio instance with baseUrl
      final dio = Dio(BaseOptions(
        baseUrl: Constants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      ));
      
      final tempDir = await getTemporaryDirectory();
      final filename = message.attachmentName ?? 'file';
      final savePath = '${tempDir.path}/$filename';
      
      // Ensure path starts with /
      String path = filePath.startsWith('/') ? filePath : '/$filePath';
      debugPrint('Downloading file for share: ${Constants.baseUrl}$path');
      await dio.download(path, savePath);
      
      if (!context.mounted) return;
      
      // Share the file
      await Share.shareXFiles(
        [XFile(savePath)],
        text: message.attachmentName ?? 'Shared file',
      );
    } catch (e) {
      debugPrint('Share error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Share failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _openDocument(BuildContext context) async {
    try {
      final filePath = _resolvedUrl();
      if (filePath.isEmpty) throw Exception('Missing file path');
      
      // Create properly configured Dio instance with baseUrl
      final dio = Dio(BaseOptions(
        baseUrl: Constants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
      ));
      
      final tempDir = await getTemporaryDirectory();
      final savePath = '${tempDir.path}/${message.attachmentName ?? 'file'}';
      
      // Ensure path starts with /
      String path = filePath.startsWith('/') ? filePath : '/$filePath';
      debugPrint('Downloading file to open: ${Constants.baseUrl}$path');
      await dio.download(path, savePath);
      
      if (!context.mounted) return;
      await OpenFile.open(savePath);
    } catch (e) {
      debugPrint('Open file error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot open file: ${e.toString()}')),
      );
    }
  }

  Widget _buildAttachment(BuildContext context) {
    if (message.isImage) {
      return _buildImageAttachment(context);
    } else {
      return _buildDocumentAttachment(context);
    }
  }

  Widget _buildImageAttachment(BuildContext context) {
    final resolvedUrl = _getFullUrl();
    return Stack(
      children: [
        GestureDetector(
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
                    height: 160,
                    color: Colors.grey.shade200,
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.broken_image),
                        const SizedBox(height: 6),
                        const Text(
                          'Failed to load image',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ImageViewerScreen(
                                      imageUrl: resolvedUrl,
                                      imageName: message.attachmentName,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.open_in_full),
                              label: const Text('Open'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _shareAttachment(context),
                              icon: const Icon(Icons.share),
                              label: const Text('Share'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _downloadAttachment(context),
                              icon: const Icon(Icons.download),
                              label: const Text('Download'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        // Action buttons overlay
        Positioned(
          top: 6,
          right: 6,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _shareAttachment(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.share, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _downloadAttachment(context),
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(Icons.download, color: Colors.white, size: 18),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDocumentAttachment(BuildContext context) {
    return Container(
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
                  'Open or download',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: 'Open',
            icon: const Icon(Icons.open_in_new),
            color: Colors.blueGrey,
            onPressed: () => _openDocument(context),
          ),
          IconButton(
            tooltip: 'Download',
            icon: const Icon(Icons.download),
            color: Colors.blueGrey,
            onPressed: () => _downloadAttachment(context),
          ),
        ],
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
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'xls':
      case 'xlsx':
      case 'csv':
        return Icons.table_chart;
      case 'txt':
      case 'rtf':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      default:
        return Icons.attach_file;
    }
  }
}
