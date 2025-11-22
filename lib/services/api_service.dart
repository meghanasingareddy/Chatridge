import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/device.dart';
import '../utils/constants.dart';
import 'cloud_file_service.dart';
import 'cloud_messaging_service.dart';

class ApiService {
  factory ApiService() => _instance;
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();

  late Dio _dio;
  bool _isInitialized = false;

  void initialize({String? customBaseUrl}) {
    if (_isInitialized && customBaseUrl == null) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: customBaseUrl ?? Constants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        // Don't set CORS headers in request - these are response headers from server
        // Mobile clients don't need these in request headers
      ),
    );

    // Add interceptors for logging and error handling
    _dio.interceptors.add(
      LogInterceptor(
        requestBody: false,
        responseBody: false,
        logPrint: (obj) => debugPrint('API: $obj'),
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          debugPrint('API Error: ${error.message}');
          handler.next(error);
        },
      ),
    );

    _isInitialized = true;
  }

  // Get all messages (with cloud fallback)
  Future<List<Message>> getMessages() async {
    // Try ESP32 first
    try {
      initialize();
      final response = await _dio.get(
        Constants.messagesEndpoint,
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch messages');
    } on DioException catch (e) {
      // If ESP32 unavailable, try cloud fallback
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('ESP32 unavailable, trying cloud messaging...');
        try {
          final cloudService = CloudMessagingService();
          final messages = await cloudService.getMessages();
          debugPrint('Cloud messaging: Fetched ${messages.length} messages');
          return messages;
        } catch (cloudError) {
          debugPrint('Cloud messaging also failed: $cloudError');
        }
      }
      throw _handleDioError(e);
    } catch (e) {
      // Try cloud fallback
      debugPrint('ESP32 error, trying cloud messaging...');
      try {
        final cloudService = CloudMessagingService();
        return await cloudService.getMessages();
      } catch (cloudError) {
        debugPrint('Cloud messaging failed: $cloudError');
      }
      throw Exception('Network error: $e');
    }
  }

  // Get connected devices (with cloud fallback)
  Future<List<Device>> getDevices() async {
    // Try ESP32 first
    try {
      initialize();
      final response = await _dio.get(
        Constants.devicesEndpoint,
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Device.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch devices');
    } on DioException catch (e) {
      // If ESP32 unavailable, try cloud fallback
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('ESP32 unavailable, trying cloud devices...');
        try {
          final cloudService = CloudMessagingService();
          return await cloudService.getDevices();
        } catch (cloudError) {
          debugPrint('Cloud devices also failed: $cloudError');
        }
      }
      throw _handleDioError(e);
    } catch (e) {
      // Try cloud fallback
      try {
        final cloudService = CloudMessagingService();
        return await cloudService.getDevices();
      } catch (cloudError) {
        debugPrint('Cloud devices failed: $cloudError');
      }
      throw Exception('Network error: $e');
    }
  }

  // Send message (with cloud fallback)
  Future<bool> sendMessage({
    required String username,
    required String text,
    String? target,
  }) async {
    // Try ESP32 first
    try {
      initialize();
      final queryParams = {
        'username': username,
        'text': text,
        if (target != null && target.isNotEmpty) 'target': target,
      };

      final response = await _dio.get(
        Constants.sendEndpoint,
        queryParameters: queryParams,
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      // If ESP32 unavailable, try cloud fallback
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('ESP32 unavailable, trying cloud messaging...');
        try {
          final cloudService = CloudMessagingService();
          final success = await cloudService.sendMessage(
            username: username,
            text: text,
            target: target,
          );
          if (success) {
            debugPrint('Message sent via cloud');
            return true;
          }
        } catch (cloudError) {
          debugPrint('Cloud messaging also failed: $cloudError');
        }
      }
      throw _handleDioError(e);
    } catch (e) {
      // Try cloud fallback
      debugPrint('ESP32 error, trying cloud messaging...');
      try {
        final cloudService = CloudMessagingService();
        final success = await cloudService.sendMessage(
          username: username,
          text: text,
          target: target,
        );
        if (success) return true;
      } catch (cloudError) {
        debugPrint('Cloud messaging failed: $cloudError');
      }
      throw Exception('Network error: $e');
    }
  }

  // Register device (with cloud fallback)
  Future<bool> registerDevice(String name) async {
    // Try ESP32 first
    try {
      initialize();
      final response = await _dio.get(
        Constants.registerEndpoint,
        queryParameters: {'name': name},
        options: Options(
          receiveTimeout: const Duration(seconds: 3),
        ),
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      // If ESP32 unavailable, try cloud fallback
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError) {
        debugPrint('ESP32 unavailable, registering in cloud...');
        try {
          final cloudService = CloudMessagingService();
          final success = await cloudService.registerDevice(name);
          if (success) {
            debugPrint('Device registered in cloud');
            return true;
          }
        } catch (cloudError) {
          debugPrint('Cloud registration also failed: $cloudError');
        }
      }
      throw _handleDioError(e);
    } catch (e) {
      // Try cloud fallback
      try {
        final cloudService = CloudMessagingService();
        final success = await cloudService.registerDevice(name);
        if (success) return true;
      } catch (cloudError) {
        debugPrint('Cloud registration failed: $cloudError');
      }
      throw Exception('Network error: $e');
    }
  }

  // Upload file (with automatic cloud fallback)
  Future<String?> uploadFile(
    File file, {
    required String username,
    String? target,
    Function(int sent, int total)? onProgress,
  }) async {
    // Try ESP32 first, fallback to cloud if unavailable
    try {
      initialize();

      debugPrint('Starting file upload: ${file.path}');
      debugPrint('File size: ${await file.length()} bytes');
      debugPrint('Username: $username, Target: $target');

      // Check if file exists and is readable
      if (!await file.exists()) {
        throw Exception('File does not exist: ${file.path}');
      }

      final fileSize = await file.length();
      if (fileSize == 0) {
        throw Exception('File is empty: ${file.path}');
      }

      if (fileSize > Constants.maxFileSizeMB * 1024 * 1024) {
        throw Exception(
            'File too large: ${(fileSize / 1024 / 1024).toStringAsFixed(1)}MB (max: ${Constants.maxFileSizeMB}MB)',);
      }

      // Handle Windows paths (backslashes) and Unix paths (forward slashes)
      // Normalize the file path for cross-platform compatibility
      final normalizedPath = file.path.replaceAll('\\', '/');
      final filename = normalizedPath.split('/').last;
      
      // Detect MIME type from file extension (critical for web and proper file handling)
      final mimeType = _detectMimeType(filename);
      
      debugPrint('Upload file info: name=$filename, size=$fileSize, mimeType=$mimeType');
      
      // Create MultipartFile with proper MIME type for web compatibility
      MultipartFile multipartFile;
      MediaType? contentType;
      if (mimeType != null) {
        final parts = mimeType.split('/');
        if (parts.length == 2) {
          contentType = MediaType(parts[0], parts[1]);
        }
      }
      
      multipartFile = MultipartFile(file.openRead(), fileSize, filename: filename, contentType: contentType);
      
      final formData = FormData.fromMap({
        'file': multipartFile,
        'username': username,
        if (target != null && target.isNotEmpty) 'target': target,
      });

      debugPrint('Sending upload request to: ${Constants.uploadEndpoint}');

      // Create a new Dio instance with shorter timeout for ESP32 (faster fallback to cloud)
      final uploadDio = Dio(
        BaseOptions(
          baseUrl: Constants.baseUrl,
          connectTimeout: const Duration(seconds: 3), // Short timeout for faster cloud fallback
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5), // Short timeout for faster cloud fallback
          // Don't set CORS headers in request - these are response headers from server
        ),
      );

      // Add request interceptor for debugging
      uploadDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            debugPrint('Upload request: ${options.method} ${options.path}');
            debugPrint('Upload headers: ${options.headers}');
            debugPrint('Upload data type: ${options.data.runtimeType}');
            handler.next(options);
          },
          onResponse: (response, handler) {
            debugPrint('Upload response: ${response.statusCode}');
            debugPrint('Upload response data: ${response.data}');
            handler.next(response);
          },
          onError: (error, handler) {
            debugPrint('Upload error: ${error.message}');
            debugPrint('Upload error type: ${error.type}');
            debugPrint('Upload error response: ${error.response?.data}');
            handler.next(error);
          },
        ),
      );

      final response = await uploadDio.post(
        Constants.uploadEndpoint,
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          receiveTimeout: const Duration(seconds: 5),
          sendTimeout: const Duration(seconds: 5), // Short timeout for faster cloud fallback
        ),
      );

      debugPrint('Upload response status: ${response.statusCode}');
      debugPrint('Upload response data: ${response.data}');

      if (response.statusCode == 200) {
        // Try different possible response formats from ESP32
        String? url;
        if (response.data is Map) {
          final data = response.data as Map<String, dynamic>;
          url = data['url'] ??
              data['filename'] ??
              data['file_url'] ??
              data['attachment_url'];
        } else if (response.data is String) {
          // If response is just a string, it might be the filename
          url = response.data;
        }

        if (url != null) {
          debugPrint('Upload successful, URL: $url');
          return url;
        } else {
          // If no URL in response, create one based on filename
          final filename = file.path.split('/').last;
          url = '/$filename';
          debugPrint('Upload successful, created URL: $url');
          return url;
        }
      } else if (response.statusCode == 413) {
        throw Exception('File too large for server');
      } else if (response.statusCode == 415) {
        throw Exception('File type not supported');
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Upload DioException: ${e.message}');
      debugPrint('Upload DioException type: ${e.type}');
      debugPrint('Upload DioException response: ${e.response?.data}');

      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
            'Upload timeout - file may be too large or connection too slow',);
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception('Cannot connect to server - check WiFi connection');
      } else if (e.type == DioExceptionType.badResponse) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 404) {
          throw Exception(
              'Upload endpoint not found - ESP32 server may not support file uploads',);
        } else if (statusCode == 500) {
          throw Exception(
              'Server error during upload - ESP32 may be out of storage',);
        }
        throw Exception('Upload failed with status: $statusCode');
      } else {
        throw Exception('Upload failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('ESP32 upload failed: $e');
      debugPrint('Attempting cloud fallback...');
      
      // Fallback to cloud service (hidden feature)
      try {
        final cloudService = CloudFileService();
        final cloudUrl = await cloudService.uploadFile(
          file,
          username: username,
          target: target,
          onProgress: onProgress,
        );
        
        if (cloudUrl != null) {
          debugPrint('Cloud upload successful: $cloudUrl');
          return cloudUrl; // Return full cloud URL
        }
      } catch (cloudError) {
        debugPrint('Cloud upload also failed: $cloudError');
        // If both fail, throw the original error
      }
      
      throw Exception('Upload error: $e');
    }
  }

  // Test connection to ESP32
  Future<bool> testConnection() async {
    try {
      initialize();
      debugPrint('Testing connection to: ${Constants.baseUrl}');

      // Try multiple endpoints to test connection
      final endpoints = ['/', '/messages', '/devices'];

      for (String endpoint in endpoints) {
        try {
          debugPrint('Testing endpoint: $endpoint');
          final response = await _dio.get(endpoint);
          debugPrint(
              'Connection test response for $endpoint: ${response.statusCode}',);
          if (response.statusCode == 200) {
            return true;
          }
        } catch (e) {
          debugPrint('Endpoint $endpoint failed: $e');
          // Continue to next endpoint
        }
      }

      return false;
    } catch (e) {
      debugPrint('Connection test failed: $e');
      return false;
    }
  }

  // Download file (with cloud support)
  Future<void> downloadFile(
    String url,
    String savePath, {
    Function(int received, int total)? onProgress,
  }) async {
    try {
      // Check if it's a cloud URL
    if (CloudFileService.isCloudUrl(url)) {
        debugPrint('Downloading from cloud: $url');
        final cloudService = CloudFileService();
        await cloudService.downloadFile(url, savePath, onProgress: onProgress);
        return;
      }
      
      // Otherwise, download from ESP32
      initialize();
      
      // Extract path from URL
      String path = url;
      if (url.startsWith(Constants.baseUrl)) {
        path = url.substring(Constants.baseUrl.length);
      } else if (url.startsWith('http')) {
        final uri = Uri.parse(url);
        path = uri.path;
      }
      
      // Ensure path starts with /
      if (!path.startsWith('/')) path = '/$path';
      
      // URL encode path parts
      final pathParts = path.split('/');
      final encodedParts = pathParts.map((part) {
        if (part.isEmpty) return part;
        return Uri.encodeComponent(part);
      }).toList();
      final encodedPath = encodedParts.join('/');
      
      debugPrint('Downloading from ESP32: ${Constants.baseUrl}$encodedPath');
      
      final dio = Dio(BaseOptions(
        baseUrl: Constants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ));
      
      await dio.download(encodedPath, savePath, onReceiveProgress: onProgress);
    } on DioException catch (e) {
      debugPrint('Download error: ${e.message}');
      if (e.response?.statusCode == 404) {
        throw Exception('File not found');
      } else {
        throw Exception('Download failed: ${e.message}');
      }
    } catch (e) {
      debugPrint('Download error: $e');
      throw Exception('Download error: $e');
    }
  }

  // Handle Dio errors
  Exception _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception(
          'Connection timeout. Please check your network connection.',
        );

      case DioExceptionType.connectionError:
        return Exception(
          'Cannot connect to Chatridge server. Please ensure you are connected to the Chatridge WiFi network.',
        );

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return Exception(
            'Chatridge server not found. Please check your connection.',
          );
        } else if (statusCode == 500) {
          return Exception('Server error. Please try again later.');
        }
        return Exception('Server error: $statusCode');

      case DioExceptionType.cancel:
        return Exception('Request cancelled');

      case DioExceptionType.unknown:
      default:
        return Exception('Network error: ${error.message}');
    }
  }

  // Cancel all requests
  void cancelAllRequests() {
    if (_isInitialized) {
      _dio.close();
      _isInitialized = false;
    }
  }

  // Detect MIME type from filename extension
  // Critical for web uploads and proper file handling on ESP32
  String? _detectMimeType(String filename) {
    final lowerFilename = filename.toLowerCase();
    
    // Images
    if (lowerFilename.endsWith('.jpg') || lowerFilename.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lowerFilename.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerFilename.endsWith('.gif')) {
      return 'image/gif';
    }
    if (lowerFilename.endsWith('.webp')) {
      return 'image/webp';
    }
    
    // Documents
    if (lowerFilename.endsWith('.pdf')) {
      return 'application/pdf';
    }
    if (lowerFilename.endsWith('.doc')) {
      return 'application/msword';
    }
    if (lowerFilename.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lowerFilename.endsWith('.xls')) {
      return 'application/vnd.ms-excel';
    }
    if (lowerFilename.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lowerFilename.endsWith('.ppt')) {
      return 'application/vnd.ms-powerpoint';
    }
    if (lowerFilename.endsWith('.pptx')) {
      return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
    }
    
    // Text files
    if (lowerFilename.endsWith('.txt')) {
      return 'text/plain';
    }
    if (lowerFilename.endsWith('.csv')) {
      return 'text/csv';
    }
    
    // Default - let ESP32 determine from extension
    return null;
  }
}
