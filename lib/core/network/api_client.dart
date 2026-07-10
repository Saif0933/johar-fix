import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';
import '../storage/storage_service.dart';

class ApiClient {
  late final Dio _dio;
  
  // Callback to execute when a 401 Unauthorized is detected
  VoidCallback? onUnauthorized;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.apiUrl,
        connectTimeout: const Duration(seconds: 90),
        receiveTimeout: const Duration(seconds: 90),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Request Interceptor: Attach Auth Token
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService.instance.getUserToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          final path = error.requestOptions.path;
          final isAuthRoute = path.contains('verify-otp') || path.contains('send-otp');
          
          if (error.response?.statusCode == 401 && !isAuthRoute) {
            debugPrint('Stale session (401 Unauthorized) detected. Clearing token...');
            try {
              await StorageService.instance.deleteUserToken();
              await StorageService.instance.deleteUserDoc();
              
              if (onUnauthorized != null) {
                onUnauthorized!();
              }
            } catch (e) {
              debugPrint('Error clearing session: $e');
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  // Cache storage
  final Map<String, _CacheEntry> _cache = {};

  void clearCache() {
    _cache.clear();
    debugPrint('ApiClient cache cleared.');
  }

  // HTTP Helper Methods
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    bool forceRefresh = false,
  }) async {
    final cacheKey = '$path?${queryParameters ?? ""}';
    if (!forceRefresh) {
      final cached = _cache[cacheKey];
      if (cached != null && !cached.isExpired) {
        debugPrint('ApiClient: returning cached response for $cacheKey');
        return cached.response;
      }
    }
    
    final response = await _dio.get(path, queryParameters: queryParameters, options: options);
    
    _cache[cacheKey] = _CacheEntry(
      response,
      DateTime.now().add(const Duration(minutes: 2)),
    );
    return response;
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    clearCache();
    return await _dio.post(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    clearCache();
    return await _dio.put(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response> delete(String path, {dynamic data, Map<String, dynamic>? queryParameters, Options? options}) async {
    clearCache();
    return await _dio.delete(path, data: data, queryParameters: queryParameters, options: options);
  }
}

class _CacheEntry {
  final Response response;
  final DateTime expiryTime;

  _CacheEntry(this.response, this.expiryTime);

  bool get isExpired => DateTime.now().isAfter(expiryTime);
}

