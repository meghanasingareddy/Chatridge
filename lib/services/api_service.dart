import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/device.dart';
import '../utils/constants.dart';

class ApiService {
  factory ApiService() => _instance;
  ApiService._internal();
  static final ApiService _instance = ApiService._internal();

  late Dio _dio;
  bool _isInitialized = false;

  void initialize() {
    if (_isInitialized) return;

    _dio = Dio(
      BaseOptions(
        baseUrl: Constants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type',
        },
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

  // Get all messages
  Future<List<Message>> getMessages() async {
    try {
      initialize();
      final response = await _dio.get(Constants.messagesEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Message.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch messages');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get connected devices
  Future<List<Device>> getDevices() async {
    try {
      initialize();
      final response = await _dio.get(Constants.devicesEndpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => Device.fromJson(json)).toList();
      }
      throw Exception('Failed to fetch devices');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Send message
  Future<bool> sendMessage({
    required String username,
    required String text,
    String? target,
  }) async {
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
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Register device
  Future<bool> registerDevice(String name) async {
    try {
      initialize();
      final response = await _dio.get(
        Constants.registerEndpoint,
        queryParameters: {'name': name},
      );

      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Upload file
  Future<String?> uploadFile(
    File file, {
    required String username,
    String? target,
    Function(int sent, int total)? onProgress,
  }) async {
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

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'username': username,
        if (target != null && target.isNotEmpty) 'target': target,
      });

      debugPrint('Sending upload request to: ${Constants.uploadEndpoint}');

      // Create a new Dio instance with longer timeout for file uploads
      final uploadDio = Dio(
        BaseOptions(
          baseUrl: Constants.baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 60),
          sendTimeout: const Duration(seconds: 60),
          headers: {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
            'Access-Control-Allow-Headers': 'Content-Type',
          },
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
      debugPrint('Upload error: $e');
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
}
