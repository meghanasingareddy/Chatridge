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

    _dio = Dio(BaseOptions(
      baseUrl: Constants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),);

    // Add interceptors for logging and error handling
    _dio.interceptors.add(LogInterceptor(
      requestBody: false,
      responseBody: false,
      logPrint: (obj) => debugPrint('API: $obj'),
    ),);

    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) {
        debugPrint('API Error: ${error.message}');
        handler.next(error);
      },
    ),);

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

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        'username': username,
        if (target != null && target.isNotEmpty) 'target': target,
      });

      final response = await _dio.post(
        Constants.uploadEndpoint,
        data: formData,
        onSendProgress: onProgress,
      );

      if (response.statusCode == 200) {
        return response.data['url'] ?? response.data['attachment_url'];
      }
      throw Exception('Upload failed');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Upload error: $e');
    }
  }

  // Test connection to ESP32
  Future<bool> testConnection() async {
    try {
      initialize();
      final response = await _dio.get('/');
      return response.statusCode == 200;
    } catch (e) {
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
            'Connection timeout. Please check your network connection.',);

      case DioExceptionType.connectionError:
        return Exception(
            'Cannot connect to Chatridge server. Please ensure you are connected to the Chatridge WiFi network.',);

      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) {
          return Exception(
              'Chatridge server not found. Please check your connection.',);
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
