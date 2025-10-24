import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'constants.dart';

class Helpers {
  // Format file size
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  // Check if file type is allowed
  static bool isAllowedFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return Constants.allowedImageTypes.contains(extension) ||
        Constants.allowedDocumentTypes.contains(extension);
  }

  // Check if file is an image
  static bool isImageFile(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    return Constants.allowedImageTypes.contains(extension);
  }

  // Get file type from extension
  static String getFileType(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    if (Constants.allowedImageTypes.contains(extension)) {
      return 'image/$extension';
    } else if (Constants.allowedDocumentTypes.contains(extension)) {
      return 'application/$extension';
    }
    return 'application/octet-stream';
  }

  // Request permissions
  static Future<bool> requestPermissions() async {
    final permissions = [
      Permission.storage,
      Permission.camera,
      Permission.photos,
    ];

    final statuses = await permissions.request();

    // Check if all permissions are granted
    return statuses.values
        .every((status) => status == PermissionStatus.granted);
  }

  // Check if connected to Chatridge network
  static bool isConnectedToChatridge(String? ssid) {
    return ssid != null && ssid.toLowerCase().contains('chatridge');
  }

  // Show snackbar
  static void showSnackBar(BuildContext context, String message,
      {Color? color,}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // Show loading dialog
  static void showLoadingDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  // Hide loading dialog
  static void hideLoadingDialog(BuildContext context) {
    Navigator.of(context).pop();
  }

  // Show error dialog
  static void showErrorDialog(
      BuildContext context, String title, String message,) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show confirmation dialog
  static Future<bool> showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // Generate unique ID
  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  // Validate username
  static bool isValidUsername(String username) {
    return username.isNotEmpty && username.length <= 20;
  }

  // Validate device name
  static bool isValidDeviceName(String deviceName) {
    return deviceName.isNotEmpty && deviceName.length <= 30;
  }

  // Get avatar color based on username
  static Color getAvatarColor(String username) {
    final colors = [
      const Color(0xFF3498DB),
      const Color(0xFFE74C3C),
      const Color(0xFF2ECC71),
      const Color(0xFFF39C12),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFFE67E22),
      const Color(0xFF34495E),
    ];

    final hash = username.hashCode;
    return colors[hash.abs() % colors.length];
  }

  // Get initials from username
  static String getInitials(String username) {
    if (username.isEmpty) return '?';
    if (username.length == 1) return username.toUpperCase();

    final words = username.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return username.substring(0, 2).toUpperCase();
  }
}
