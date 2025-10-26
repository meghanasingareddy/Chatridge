import 'dart:io';
import 'package:flutter/material.dart';
import '../services/file_service.dart';
import '../utils/helpers.dart';

class FileAttachmentButton extends StatelessWidget {
  const FileAttachmentButton({
    super.key,
    this.onFileSelected,
    this.isEnabled = true,
  });
  final Function(File)? onFileSelected;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.attach_file),
      onPressed: isEnabled ? () => _showFileOptions(context) : null,
      color: isEnabled ? Colors.grey.shade600 : Colors.grey.shade400,
    );
  }

  void _showFileOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.attach_file),
                  const SizedBox(width: 8),
                  const Text(
                    'Attach File',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Options
            ListTile(
              leading: const Icon(Icons.photo_camera, color: Colors.blue),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select from photo library'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.orange),
              title: const Text('Choose File'),
              subtitle: const Text('Select any file from device'),
              onTap: () {
                Navigator.pop(context);
                _pickFile(context);
              },
            ),

            // File size limit info
            Container(
              padding: const EdgeInsets.all(16),
              child: Text(
                FileService().getFileSizeLimitDescription(),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    try {
      final fileService = FileService();
      final file = await fileService.pickFile();
      if (file != null) {
        onFileSelected?.call(file);
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error picking file: $e',
        color: Colors.red,
      );
    }
  }

  Future<void> _pickImageFromCamera(BuildContext context) async {
    try {
      final fileService = FileService();
      final file = await fileService.pickImageFromCamera();
      if (file != null) {
        onFileSelected?.call(file);
      }
    } catch (e) {
      Helpers.showSnackBar(
        context,
        'Error taking photo: $e',
        color: Colors.red,
      );
    }
  }

  Future<void> _pickImageFromGallery(BuildContext context) async {
    try {
      final fileService = FileService();
      final file = await fileService.pickImageFromGallery();
      if (file != null) {
        onFileSelected?.call(file);
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
}
