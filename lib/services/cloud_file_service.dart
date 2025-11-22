import 'dart:io';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../utils/constants.dart';

/// Hidden cloud file service for normal internet connectivity
/// This service works automatically when ESP32 is unavailable
class CloudFileService {
  factory CloudFileService() => _instance;
  CloudFileService._internal();
  static final CloudFileService _instance = CloudFileService._internal();

  late Dio _dio;
  bool _isInitialized = false;
  
  // Using a free file hosting service (0x0.st) as fallback
  // This is completely transparent to the user
  static const String _cloudUploadUrl = 'https://0x0.st';
  static const String _cloudBaseUrl = 'https://0x0.st';
  
  void _initialize() {
    if (_isInitialized) return;
    
    _dio = Dio(
      BaseOptions(
        baseUrl: _cloudBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    
    _isInitialized = true;
  }

  /// Upload file to cloud storage (hidden feature)
  Future<String?> uploadFile(
    File file, {
    required String username,
    String? target,
    Function(int sent, int total)? onProgress,
  }) async {
    try {
      _initialize();
      
      debugPrint('CloudFileService: Starting cloud upload');
      debugPrint('File path: ${file.path}');
      
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }

      if (fileSize > Constants.maxFileSizeMB * 1024 * 1024) {
        throw Exception(
            'File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB (max: ${Constants.maxFileSizeMB}MB)');
      }

      final normalizedPath = file.path.replaceAll('\\', '/');
      final filename = normalizedPath.split('/').last;
      
      // Create form data for 0x0.st
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: filename,
        ),
      });

      debugPrint('CloudFileService: Uploading to cloud...');
      
      final response = await _dio.post(
        '/',
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // 0x0.st returns the URL directly as text/plain
        String? url;
        if (response.data is String) {
          url = (response.data as String).trim();
        } else {
          url = response.data.toString().trim();
        }
        
        // Remove any quotes or whitespace
        url = url.replaceAll('"', '').replaceAll("'", '').trim();
        
        // Ensure it's a full URL
        if (url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
          if (url.startsWith('/')) {
            url = '$_cloudBaseUrl$url';
          } else {
            url = '$_cloudBaseUrl/$url';
          }
        }
        
        if (url.isEmpty) {
          throw Exception('Cloud service returned empty URL');
        }
        
        debugPrint('CloudFileService: Upload successful, URL: $url');
        return url;
      } else {
        throw Exception('Cloud upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('CloudFileService: Upload error: ${e.message}');
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception('Cloud upload timeout - connection too slow');
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to cloud service');
      } else {
        throw Exception('Cloud upload failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('CloudFileService: Upload error: $e');
      throw Exception('Cloud upload error: $e');
    }
  }

  /// Download file from cloud storage
  Future<void> downloadFile(
    String url,
    String savePath, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      _initialize();
      
      debugPrint('CloudFileService: Downloading from cloud: $url');
      
      // If URL is already full, use it directly
      final downloadUrl = url.startsWith('http') ? url : '$_cloudBaseUrl$url';
      
      await _dio.download(
        downloadUrl,
        savePath,
        onReceiveProgress: onProgress,
      );
      
      debugPrint('CloudFileService: Download successful: $savePath');
    } on DioException catch (e) {
      debugPrint('CloudFileService: Download error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('File not found in cloud storage');
      } else {
        throw Exception('Cloud download failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('CloudFileService: Download error: $e');
      throw Exception('Cloud download error: $e');
    }
  }

  /// Check if URL is a cloud URL
  static bool isCloudUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    if (!url.startsWith('http://') && !url.startsWith('https://')) return false;
    // Check if it's NOT the ESP32 base URL
    final esp32Host = Constants.baseUrl.replaceFirst('http://', '').replaceFirst('https://', '');
    return !url.contains(esp32Host);
  }

  /// Get full URL for cloud file
  static String getFullCloudUrl(String url) {
    if (url.startsWith('http')) return url;
    return '$_cloudBaseUrl$url';
  }
}

