import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../services/file_service.dart';
import '../services/storage_service.dart';
import '../utils/helpers.dart';

class InputArea extends StatefulWidget {
  const InputArea({
    super.key,
    this.onMessageSent,
    this.selectedTarget,
    this.onTargetSelected,
  });
  final VoidCallback? onMessageSent;
  final String? selectedTarget;
  final Function(String?)? onTargetSelected;

  @override
  State<InputArea> createState() => _InputAreaState();
}

class _InputAreaState extends State<InputArea> {
  final TextEditingController _messageController = TextEditingController();
  final FileService _fileService = FileService();
  bool _isSending = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
    });

    try {
      final username = StorageService.getUsername() ?? 'Unknown';
      final success = await context.read<ChatProvider>().sendMessage(
            username: username,
            text: text,
            target: widget.selectedTarget,
          );

      if (success) {
        _messageController.clear();
        widget.onMessageSent?.call();
      } else {
        Helpers.showSnackBar(
          context,
          'Failed to send message',
          color: Colors.red,
        );
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error: $e',
        color: Colors.red,
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await _fileService.pickFile();
      if (file != null) {
        await _sendFile(file);
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error picking file: $e',
        color: Colors.red,
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final file = await _fileService.pickImageFromCamera();
      if (file != null) {
        await _sendFile(file);
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error taking photo: $e',
        color: Colors.red,
      );
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final file = await _fileService.pickImageFromGallery();
      if (file != null) {
        await _sendFile(file);
      }
    } catch (e) {
      // Show more user-friendly error message for permission issues
      String errorMessage = e.toString();
      if (errorMessage.contains('permission')) {
        errorMessage =
            'Permission required to access gallery. Please grant photo permission in settings.';
      }
      Helpers.showSnackBar(
        context,
        'Error picking image: $errorMessage',
        color: Colors.red,
      );
    }
  }

  Future<void> _sendFile(File file) async {
    setState(() {
      _isSending = true;
    });

    try {
      final username = StorageService.getUsername() ?? 'Unknown';
      final success = await context.read<ChatProvider>().sendFile(
            username: username,
            filePath: file.path,
            target: widget.selectedTarget,
            onProgress: (sent, total) {
              // TODO: Show upload progress
              debugPrint('Upload progress: $sent/$total');
            },
          );

      if (success) {
        widget.onMessageSent?.call();
        Helpers.showSnackBar(
          context,
          'File sent successfully',
          color: Colors.green,
        );
      } else {
        Helpers.showSnackBar(
          context,
          'Failed to send file - check connection and try again',
          color: Colors.red,
        );
      }
    } catch (e) {
      String errorMessage = e.toString();

      // Provide more specific error messages
      if (errorMessage.contains('timeout')) {
        errorMessage =
            'Upload timeout - try a smaller file or check connection';
      } else if (errorMessage.contains('too large')) {
        errorMessage = 'File too large - maximum size is 10MB';
      } else if (errorMessage.contains('connection')) {
        errorMessage = 'Cannot connect to server - check WiFi connection';
      } else if (errorMessage.contains('permission')) {
        errorMessage = 'Permission denied - check app permissions';
      } else if (errorMessage.contains('not supported')) {
        errorMessage = 'File type not supported';
      }

      Helpers.showSnackBar(
        context,
        'Error sending file: $errorMessage',
        color: Colors.red,
      );
    } finally {
      setState(() {
        _isSending = false;
      });
    }
  }

  void _showFileOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Only show camera option on mobile platforms
            if (!kIsWeb) ...[
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Choose File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        children: [
          // Target selection
          if (widget.selectedTarget != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'To: ${widget.selectedTarget}',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => widget.onTargetSelected?.call(null),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Input row
          Row(
            children: [
              // Attachment button
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: _isSending ? null : _showFileOptions,
                color: Colors.grey.shade600,
              ),

              // Message input
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(24)),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),

              const SizedBox(width: 8),

              // Send button
              DecoratedBox(
                decoration: BoxDecoration(
                  color: _isSending ? Colors.grey : const Color(0xFF3498DB),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isSending ? null : _sendMessage,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
