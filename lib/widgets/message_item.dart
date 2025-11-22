import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/foundation.dart';
import 'package:open_file/open_file.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message.dart';
import '../utils/helpers.dart';
import '../screens/image_viewer_screen.dart';
import '../utils/constants.dart';
import '../services/storage_service.dart';

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
    final myUsername = StorageService.getUsername();
    final myDeviceName = StorageService.getDeviceName();
    final isMe = message.username == myUsername || 
                 message.username == myDeviceName ||
                 (myUsername == null && message.username == 'You');
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
                      // Message text with URL detection
                      if (message.text.isNotEmpty) ...[
                        _buildMessageText(context, message.text, isMe),
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

  // Sanitize filename to match ESP32's sanitizeFilename function
  // ESP32 replaces commas, parentheses, and other special chars with underscores
  // But keeps spaces, alphanumeric, dots, hyphens, and underscores
  String _sanitizeFilename(String filename) {
    // Remove leading slash if present for processing
    final needsSlash = filename.startsWith('/');
    final clean = needsSlash ? filename.substring(1) : filename;
    
    // This regex replaces any character that is NOT a letter, number, space, dot, hyphen, or underscore.
    // This should more accurately match the ESP32's sanitization logic.
    // It handles characters like `|`, `(`, `)`, `,`, etc., by replacing them with `_`.
    final sanitized = clean.replaceAll(RegExp(r'[^a-zA-Z0-9 ._-]'), '_');
    
    return needsSlash ? '/$sanitized' : sanitized;
  }

  String _resolvedUrl() {
    if (!message.hasAttachment) return '';
    final raw = message.attachmentUrl!;
    
    debugPrint('_resolvedUrl: raw attachmentUrl = "$raw"');
    
    // Return just the path, not full URL (Dio will use baseUrl)
    final path = raw.startsWith('http') ? raw.replaceFirst(RegExp(r'^https?://[^/]+'), '') : raw;
    
    debugPrint('_resolvedUrl: extracted path = "$path"');
    
    // Check if filename needs sanitization (has commas or parentheses)
    // ESP32 sanitizes on upload, but old messages might have unsanitized names
    if (path.isNotEmpty && path.contains('/')) {
      final pathParts = path.split('/');
      if (pathParts.length > 1) {
        final filename = pathParts.last;
        debugPrint('_resolvedUrl: filename from path = "$filename"');
        
        // Check if filename needs sanitization (contains commas or parentheses)
        final needsSanitization = filename.contains(',') || 
                                  filename.contains('(') || 
                                  filename.contains(')');
        
        if (needsSanitization) {
          debugPrint('_resolvedUrl: filename needs sanitization (contains special chars)');
          final sanitizedFilename = _sanitizeFilename(filename);
          debugPrint('_resolvedUrl: sanitized filename = "$sanitizedFilename"');
          
          // Reconstruct path with sanitized filename
          pathParts[pathParts.length - 1] = sanitizedFilename.startsWith('/') 
              ? sanitizedFilename.substring(1) 
              : sanitizedFilename;
          final finalPath = pathParts.join('/');
          debugPrint('_resolvedUrl: final sanitized path = "$finalPath"');
          return finalPath;
        } else {
          debugPrint('_resolvedUrl: filename already sanitized, using as-is');
        }
      }
    }
    
    debugPrint('_resolvedUrl: returning path = "$path"');
    return path;
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
      
      debugPrint('Downloading attachment: original URL=${message.attachmentUrl}, resolved=$filePath');
      
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
      
      // Get download directory (custom or default)
      final dir = await StorageService.getDownloadDirectory();
      final downloadDir = Directory(dir);
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }
      
      // Use attachment name, fallback to filename from URL (sanitized)
      String filename = message.attachmentName ?? 'file';
      if (filename.isEmpty) {
        final pathParts = filePath.split('/');
        filename = pathParts.isNotEmpty ? pathParts.last : 'file';
      }
      
      // Sanitize filename for local filesystem (remove invalid Windows chars)
      filename = filename.replaceAll(RegExp(r'[<>:"|?*]'), '_');
      
      final savePath = Platform.isWindows 
          ? '$dir\\$filename' 
          : '$dir/$filename';
      
      // Normalize path - ensure it starts with / and doesn't have double slashes
      String path = filePath.startsWith('/') ? filePath : '/$filePath';
      path = path.replaceAll(RegExp(r'//+'), '/'); // Remove double slashes
      
      // URL encode the path to handle special characters (spaces, etc.)
      // Split path into parts and encode each part separately
      final pathParts = path.split('/');
      final encodedParts = pathParts.map((part) {
        if (part.isEmpty) return part;
        return Uri.encodeComponent(part);
      }).toList();
      final encodedPath = encodedParts.join('/');
      
      debugPrint('Downloading file: ${Constants.baseUrl}$encodedPath -> $savePath');
      debugPrint('Original path: $path, Encoded path: $encodedPath');
      
      try {
        await dio.download(encodedPath, savePath);
        debugPrint('File downloaded successfully: $savePath');
      } on DioException catch (e) {
        debugPrint('Download error: ${e.message}');
        debugPrint('Response: ${e.response?.data}');
        debugPrint('Status code: ${e.response?.statusCode}');
        
        if (e.response?.statusCode == 404) {
          throw Exception('File not found on server. Path: $path');
        } else if (e.response?.statusCode == 500) {
          throw Exception('Server error while downloading file');
        } else {
          throw Exception('Failed to download file: ${e.message}');
        }
      }
      
      // Verify file was downloaded
      final downloadedFile = File(savePath);
      if (!await downloadedFile.exists()) {
        throw Exception('Downloaded file not found');
      }
      
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved to $savePath'),
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      debugPrint('Download error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Download failed: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
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
      
      // Use download directory for shared files too
      final dir = await StorageService.getDownloadDirectory();
      final downloadDir = Directory(dir);
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }
      
      String filename = message.attachmentName ?? 'file';
      if (filename.isEmpty) {
        final pathParts = filePath.split('/');
        filename = pathParts.isNotEmpty ? pathParts.last : 'file';
      }
      
      // Sanitize filename for local filesystem
      filename = filename.replaceAll(RegExp(r'[<>:"|?*]'), '_');
      final savePath = Platform.isWindows 
          ? '$dir\\$filename' 
          : '$dir/$filename';
      
      // Normalize path - ensure it starts with / and doesn't have double slashes
      String path = filePath.startsWith('/') ? filePath : '/$filePath';
      path = path.replaceAll(RegExp(r'//+'), '/'); // Remove double slashes
      
      // URL encode the path to handle special characters
      final pathParts = path.split('/');
      final encodedParts = pathParts.map((part) {
        if (part.isEmpty) return part;
        return Uri.encodeComponent(part);
      }).toList();
      final encodedPath = encodedParts.join('/');
      
      debugPrint('Downloading file for share: ${Constants.baseUrl}$encodedPath');
      debugPrint('Original path: $path, Encoded path: $encodedPath');
      await dio.download(encodedPath, savePath);
      
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
      if (filePath.isEmpty) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Missing file path')),
        );
        return;
      }
      
      debugPrint('Opening document: original URL=${message.attachmentUrl}, resolved=$filePath');
      
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
      
      // Get download directory (custom or default) for opening files
      // We use download directory so files can be opened after download
      final dir = await StorageService.getDownloadDirectory();
      final downloadDir = Directory(dir);
      if (!downloadDir.existsSync()) {
        downloadDir.createSync(recursive: true);
      }
      
      // Use attachment name, fallback to filename from URL (use sanitized version)
      String fileName = message.attachmentName ?? 'file';
      if (fileName.isEmpty) {
        // Extract filename from URL path
        final pathParts = filePath.split('/');
        fileName = pathParts.isNotEmpty ? pathParts.last : 'file';
      }
      
      // Preserve file extension - extract it first
      String fileExtension = '';
      final extMatch = RegExp(r'\.([^.]+)$').firstMatch(fileName);
      if (extMatch != null) {
        fileExtension = extMatch.group(1) ?? '';
      }
      
      // Sanitize filename for local filesystem (remove invalid Windows chars)
      // Keep the extension safe
      String baseName = fileName;
      if (fileExtension.isNotEmpty) {
        baseName = fileName.substring(0, fileName.length - fileExtension.length - 1);
      }
      
      // Remove invalid Windows characters but keep spaces (they're fine in Windows)
      baseName = baseName.replaceAll(RegExp(r'[<>:"|?*]'), '_');
      // Also remove backslashes and forward slashes
      baseName = baseName.replaceAll(RegExp(r'[/\\]'), '_');
      
      // Reconstruct filename with extension
      fileName = fileExtension.isNotEmpty ? '$baseName.$fileExtension' : baseName;
      
      // Ensure filename is not empty
      if (fileName.isEmpty || fileName == '.') {
        fileName = 'file${fileExtension.isNotEmpty ? '.$fileExtension' : ''}';
      }
      
      final savePath = Platform.isWindows 
          ? '$dir\\$fileName' 
          : '$dir/$fileName';
      
      // Normalize path - ensure it starts with / and doesn't have double slashes
      String path = filePath.startsWith('/') ? filePath : '/$filePath';
      path = path.replaceAll(RegExp(r'//+'), '/'); // Remove double slashes
      
      // Try multiple path formats to handle different scenarios
      final pathsToTry = <String>[];
      
      // 1. Sanitized path (what we expect from ESP32)
      pathsToTry.add(path);
      
      // 2. If path has underscores that might have been spaces, try with original special chars
      // But only if the original message URL had special chars
      if (message.attachmentUrl != null && 
          (message.attachmentUrl!.contains(',') || 
           message.attachmentUrl!.contains('(') || 
           message.attachmentUrl!.contains(')'))) {
        // Try the original unsanitized path as fallback
        final originalPath = message.attachmentUrl!.startsWith('/') 
            ? message.attachmentUrl! 
            : '/${message.attachmentUrl!}';
        pathsToTry.add(originalPath);
      }
      
      // Try each path format
      bool downloadSuccess = false;
      DioException? lastError;
      
      for (final tryPath in pathsToTry) {
        // URL encode the path to handle special characters (spaces, etc.)
        final pathParts = tryPath.split('/');
        final encodedParts = pathParts.map((part) {
          if (part.isEmpty) return part;
          return Uri.encodeComponent(part);
        }).toList();
        final encodedPath = encodedParts.join('/');
        
        debugPrint('Trying to download: ${Constants.baseUrl}$encodedPath -> $savePath');
        
        try {
          await dio.download(encodedPath, savePath);
          final downloadedFile = File(savePath);
          if (await downloadedFile.exists() && await downloadedFile.length() > 0) {
            downloadSuccess = true;
            debugPrint('File downloaded successfully: $savePath');
            break;
          }
        } on DioException catch (e) {
          debugPrint('Download error for path $tryPath: ${e.message}');
          debugPrint('Status code: ${e.response?.statusCode}');
          lastError = e;
          // Continue to try next path
        } catch (e) {
          debugPrint('Unexpected error: $e');
          lastError = DioException(
            requestOptions: RequestOptions(path: tryPath),
            type: DioExceptionType.unknown,
            error: e,
          );
        }
      }
      
      if (!downloadSuccess) {
        if (!context.mounted) return;
        
        // Show detailed error with all attempted paths
        final originalUrl = message.attachmentUrl ?? 'null';
        final resolvedUrl = filePath;
        
        String errorMsg = '❌ File not found on server.\n\n';
        errorMsg += '📁 Original URL: $originalUrl\n';
        errorMsg += '🔍 Resolved path: $resolvedUrl\n';
        errorMsg += '📝 Attempted paths:\n';
        for (int i = 0; i < pathsToTry.length; i++) {
          errorMsg += '  ${i + 1}. ${pathsToTry[i]}\n';
        }
        
        if (lastError?.response?.statusCode == 404) {
          errorMsg += '\n⚠️ All paths returned 404. The file may not exist on ESP32.';
        } else if (lastError?.response?.statusCode == 500) {
          errorMsg += '\n⚠️ Server error (500). ESP32 may be having issues.';
        } else {
          errorMsg += '\n⚠️ Error: ${lastError?.message ?? "Unknown error"}';
        }
        
        errorMsg += '\n\n💡 Try re-uploading the file, or check ESP32 Serial Monitor for available files.';
        
        // Show as dialog instead of snackbar for better readability
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('File Not Found'),
            content: SingleChildScrollView(
              child: Text(
                errorMsg,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Try to copy error to clipboard would be nice, but keep it simple
                },
                child: const Text('Copy Error'),
              ),
            ],
          ),
        );
        return;
      }
      
      // Verify file was downloaded
      final downloadedFile = File(savePath);
      if (!await downloadedFile.exists()) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaded file not found')),
        );
        return;
      }
      
      final fileSize = await downloadedFile.length();
      if (fileSize == 0) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Downloaded file is empty')),
        );
        return;
      }
      
      debugPrint('File ready to open: $savePath (${fileSize} bytes)');
      
      if (!context.mounted) return;
      
      // On Windows, try multiple methods to open the file
      bool openedSuccessfully = false;
      
      if (Platform.isWindows) {
        // Method 1: Use url_launcher with file URI (most reliable for Windows)
        try {
          // Normalize path to Windows format
          final normalizedPath = savePath.replaceAll('/', '\\');
          
          // Verify file exists before trying to open
          final file = File(normalizedPath);
          if (!await file.exists()) {
            throw Exception('File not found: $normalizedPath');
          }
          
          // Use file URI - Windows handles this natively
          final fileUri = Uri.file(normalizedPath);
          if (await canLaunchUrl(fileUri)) {
            await launchUrl(fileUri, mode: LaunchMode.externalApplication);
            openedSuccessfully = true;
            debugPrint('File opened using url_launcher: $normalizedPath');
          } else {
            throw Exception('Cannot launch file URI');
          }
        } catch (e) {
          debugPrint('url_launcher failed: $e');
          
          // Method 2: Try open_file package
          try {
            final result = await OpenFile.open(savePath);
            debugPrint('OpenFile result: ${result.type}, message: ${result.message}');
            if (result.type == ResultType.done) {
              openedSuccessfully = true;
              debugPrint('File opened using OpenFile package');
            } else if (result.type == ResultType.noAppToOpen) {
              // If no app found, show message with file location
              debugPrint('No app found to open file');
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('No application found to open this file type. File saved to: $savePath'),
                  duration: const Duration(seconds: 5),
                ),
              );
              return; // Don't try other methods if no app available
            }
          } catch (e2) {
            debugPrint('OpenFile package failed: $e2');
            
            // Method 3: Try Windows explorer to show file location
            try {
              final normalizedPath = savePath.replaceAll('/', '\\');
              final directory = normalizedPath.substring(0, normalizedPath.lastIndexOf('\\'));
              final fileUri = Uri.file(directory);
              if (await canLaunchUrl(fileUri)) {
                await launchUrl(fileUri, mode: LaunchMode.externalApplication);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('File saved. Opening folder: $directory'),
                    duration: const Duration(seconds: 3),
                  ),
                );
                return;
              }
            } catch (e3) {
              debugPrint('Failed to open folder: $e3');
            }
          }
        }
      } else {
        // Non-Windows platforms: use open_file package
        try {
          final result = await OpenFile.open(savePath);
          if (result.type == ResultType.done) {
            openedSuccessfully = true;
            debugPrint('File opened successfully');
          }
        } catch (e) {
          debugPrint('OpenFile failed: $e');
        }
      }
      
      // Only show error if all methods failed
      if (!openedSuccessfully) {
        if (!context.mounted) return;
        // Show file location clearly so user can manually open it
        final normalizedPath = savePath.replaceAll('/', '\\');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('File saved to:\n$normalizedPath'),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Open Folder',
              onPressed: () async {
                try {
                  final directory = normalizedPath.substring(0, normalizedPath.lastIndexOf('\\'));
                  final fileUri = Uri.file(directory);
                  if (await canLaunchUrl(fileUri)) {
                    await launchUrl(fileUri, mode: LaunchMode.externalApplication);
                  }
                } catch (e) {
                  debugPrint('Failed to open folder: $e');
                }
              },
            ),
          ),
        );
      }
      // If opened successfully, don't show any message (silent success)
    } catch (e) {
      debugPrint('Open file error: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cannot open file: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
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

  String _getEncodedFullUrl() {
    if (!message.hasAttachment) return '';
    final raw = message.attachmentUrl!;
    String url;
    if (raw.startsWith('http')) {
      url = raw;
    } else {
      String path = raw.startsWith('/') ? raw : '/$raw';
      path = path.replaceAll(RegExp(r'//+'), '/');
      // URL encode path parts
      final pathParts = path.split('/');
      final encodedParts = pathParts.map((part) {
        if (part.isEmpty) return part;
        return Uri.encodeComponent(part);
      }).toList();
      final encodedPath = encodedParts.join('/');
      url = '${Constants.baseUrl}$encodedPath';
    }
    return url;
  }

  Widget _buildImageAttachment(BuildContext context) {
    final resolvedUrl = _getEncodedFullUrl();
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
    return GestureDetector(
      onTap: () => _openDocument(context),
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
            const SizedBox(width: 8),
            IconButton(
              tooltip: 'Download',
              icon: const Icon(Icons.download),
              color: Colors.blueGrey,
              onPressed: () => _downloadAttachment(context),
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

  Widget _buildMessageText(BuildContext context, String text, bool isMe) {
    // Check if text contains URLs
    if (!Helpers.containsUrl(text)) {
      return Text(
        text,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
      );
    }

    // Extract URLs and create clickable text using regex
    final urlPattern = RegExp(
      r'(https?://[^\s]+|www\.[^\s]+|[a-zA-Z0-9-]+\.[a-zA-Z]{2,}[^\s]*)',
      caseSensitive: false,
    );
    
    final parts = <TextSpan>[];
    int lastIndex = 0;
    
    for (final match in urlPattern.allMatches(text)) {
      // Add text before URL
      if (match.start > lastIndex) {
        parts.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 14,
          ),
        ));
      }

      // Process the matched URL
      String url = match.group(0)!;
      String displayUrl = url;
      
      // Ensure URL has protocol
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        url = 'https://$url';
      }
      
      // Truncate display URL if too long
      final originalUrl = match.group(0)!;
      if (originalUrl.length > 50) {
        displayUrl = '${originalUrl.substring(0, 47)}...';
      }

      // Add clickable URL
      parts.add(TextSpan(
        text: displayUrl,
        style: TextStyle(
          color: isMe ? Colors.lightBlue.shade100 : Colors.blue,
          fontSize: 14,
          decoration: TextDecoration.underline,
          decorationColor: isMe ? Colors.lightBlue.shade100 : Colors.blue,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () => _launchUrl(context, url),
      ));

      lastIndex = match.end;
    }

    // Add remaining text
    if (lastIndex < text.length) {
      parts.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
      ));
    }

    if (parts.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          color: isMe ? Colors.white : Colors.black87,
          fontSize: 14,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: parts),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open URL: $url')),
        );
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error opening URL: ${e.toString()}')),
      );
    }
  }
}
