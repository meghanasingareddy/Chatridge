import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class Permissions {
  // Check if storage permission is granted
  static Future<bool> isStoragePermissionGranted() async {
    if (kIsWeb) return true; // Web doesn't need storage permission
    try {
      final status = await Permission.storage.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return true; // Assume granted if permission check fails
    }
  }

  // Check if camera permission is granted
  static Future<bool> isCameraPermissionGranted() async {
    if (kIsWeb) return true; // Web handles camera permission differently
    try {
      final status = await Permission.camera.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return true; // Assume granted if permission check fails
    }
  }

  // Check if photos permission is granted
  static Future<bool> isPhotosPermissionGranted() async {
    if (kIsWeb) return true; // Web doesn't need photos permission
    try {
      final status = await Permission.photos.status;
      return status == PermissionStatus.granted;
    } catch (e) {
      return true; // Assume granted if permission check fails
    }
  }

  // Request storage permission
  static Future<bool> requestStoragePermission() async {
    if (kIsWeb) return true; // Web doesn't need storage permission
    try {
      final status = await Permission.storage.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return true; // Assume granted if permission request fails
    }
  }

  // Request camera permission
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true; // Web handles camera permission differently
    try {
      final status = await Permission.camera.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return true; // Assume granted if permission request fails
    }
  }

  // Request photos permission
  static Future<bool> requestPhotosPermission() async {
    if (kIsWeb) return true; // Web doesn't need photos permission
    try {
      final status = await Permission.photos.request();
      return status == PermissionStatus.granted;
    } catch (e) {
      return true; // Assume granted if permission request fails
    }
  }

  // Request all necessary permissions
  static Future<Map<String, bool>> requestAllPermissions() async {
    if (kIsWeb) {
      return {
        'storage': true,
        'camera': true,
        'photos': true,
      };
    }

    final results = <String, bool>{};
    results['storage'] = await requestStoragePermission();
    results['camera'] = await requestCameraPermission();
    results['photos'] = await requestPhotosPermission();
    return results;
  }

  // Check if all permissions are granted
  static Future<bool> areAllPermissionsGranted() async {
    if (kIsWeb) return true; // Web doesn't need these permissions
    final storage = await isStoragePermissionGranted();
    final camera = await isCameraPermissionGranted();
    final photos = await isPhotosPermissionGranted();
    return storage && camera && photos;
  }

  // Open app settings
  static Future<void> openAppSettings() async {
    if (kIsWeb) return; // Web doesn't have app settings
    try {
      await openAppSettings();
    } catch (e) {
      // Ignore errors on web
    }
  }

  // Check permission status with detailed info
  static Future<Map<String, PermissionStatus>> getPermissionStatuses() async {
    if (kIsWeb) {
      return {
        'storage': PermissionStatus.granted,
        'camera': PermissionStatus.granted,
        'photos': PermissionStatus.granted,
      };
    }

    try {
      return {
        'storage': await Permission.storage.status,
        'camera': await Permission.camera.status,
        'photos': await Permission.photos.status,
      };
    } catch (e) {
      return {
        'storage': PermissionStatus.granted,
        'camera': PermissionStatus.granted,
        'photos': PermissionStatus.granted,
      };
    }
  }
}
