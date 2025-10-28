import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';
import '../utils/permissions.dart';

class FileService {
  factory FileService() => _instance;
  FileService._internal();
  static final FileService _instance = FileService._internal();

  final ImagePicker _imagePicker = ImagePicker();

  // Pick file from device storage
  Future<File?> pickFile() async {
    Future<File?> doPick() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
        withData: kIsWeb,
        withReadStream: false,
      );
      if (result == null || result.files.isEmpty) return null;

      final pickedFile = result.files.first;
      File file;
      if (kIsWeb && pickedFile.bytes != null) {
        final tempDir = Directory.systemTemp;
        final tempFile = File('${tempDir.path}/${pickedFile.name}');
        await tempFile.writeAsBytes(pickedFile.bytes!);
        file = tempFile;
      } else {
        if (pickedFile.path == null) {
          throw Exception('No file path returned');
        }
        file = File(pickedFile.path!);
      }

      final fileSize = await file.length();
      if (fileSize > Constants.maxFileSizeMB * 1024 * 1024) {
        throw Exception('File size exceeds ${Constants.maxFileSizeMB}MB limit');
      }
      if (!Helpers.isAllowedFileType(file.path)) {
        throw Exception('File type not supported');
      }
      return file;
    }

    try {
      // Try without pre-requesting permission (many devices allow picker UI)
      return await doPick();
    } catch (e) {
      // If permission-related, request then retry once
      final message = e.toString().toLowerCase();
      if (!kIsWeb &&
          (message.contains('permission') || message.contains('denied'))) {
        final granted = await Permissions.requestStoragePermission();
        if (granted) {
          return await doPick();
        }
      }
      throw Exception('Failed to pick file: $e');
    }
  }

  // Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      // Check camera permission (skip on web)
      if (!kIsWeb && !await Permissions.isCameraPermissionGranted()) {
        final granted = await Permissions.requestCameraPermission();
        if (!granted) {
          throw Exception('Camera permission is required to take photos');
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);

        // Validate file size
        final fileSize = await file.length();
        if (fileSize > Constants.maxFileSizeMB * 1024 * 1024) {
          throw Exception(
            'Image size exceeds ${Constants.maxFileSizeMB}MB limit',
          );
        }

        return file;
      }
      return null;
    } catch (e) {
      if (kIsWeb) {
        throw Exception(
            'Camera not available on web. Please use "Choose from Gallery" instead.',);
      }
      throw Exception('Failed to capture image: $e');
    }
  }

  // Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      // Check photos permission (skip on web)
      if (!kIsWeb && !await Permissions.isPhotosPermissionGranted()) {
        final granted = await Permissions.requestPhotosPermission();
        if (!granted) {
          throw Exception(
              'Photo permission is required to access gallery. Please grant permission in settings.',);
        }
      }

      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        final file = File(image.path);

        // Validate file size
        final fileSize = await file.length();
        if (fileSize > Constants.maxFileSizeMB * 1024 * 1024) {
          throw Exception(
            'Image size exceeds ${Constants.maxFileSizeMB}MB limit',
          );
        }

        return file;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to pick image: $e');
    }
  }

  // Get file info
  Future<Map<String, dynamic>> getFileInfo(File file) async {
    final stat = await file.stat();
    final fileName = file.path.split('/').last;

    return {
      'name': fileName,
      'size': stat.size,
      'sizeFormatted': Helpers.formatFileSize(stat.size),
      'type': Helpers.getFileType(fileName),
      'isImage': Helpers.isImageFile(fileName),
      'path': file.path,
    };
  }

  // Validate file
  Future<bool> validateFile(File file) async {
    try {
      // Check if file exists
      if (!await file.exists()) {
        return false;
      }

      // Check file size
      final fileSize = await file.length();
      if (fileSize > Constants.maxFileSizeMB * 1024 * 1024) {
        return false;
      }

      // Check file type
      if (!Helpers.isAllowedFileType(file.path)) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  // Get supported file types
  List<String> getSupportedFileTypes() {
    return [
      ...Constants.allowedImageTypes,
      ...Constants.allowedDocumentTypes,
    ];
  }

  // Get file type description
  String getFileTypeDescription(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();

    if (Constants.allowedImageTypes.contains(extension)) {
      return 'Image file';
    } else if (Constants.allowedDocumentTypes.contains(extension)) {
      return 'Document file';
    }

    return 'Unknown file type';
  }

  // Check if file is too large
  bool isFileTooLarge(int fileSizeBytes) {
    return fileSizeBytes > Constants.maxFileSizeMB * 1024 * 1024;
  }

  // Get file size limit description
  String getFileSizeLimitDescription() {
    return 'Maximum file size: ${Constants.maxFileSizeMB}MB';
  }
}
