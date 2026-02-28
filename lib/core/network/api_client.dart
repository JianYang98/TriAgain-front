import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_exception.dart';
import 'api_response.dart';

const _baseUrl = 'http://localhost:8080';
const _tempUserId = 'test-user-1';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

class ApiClient {
  late final Dio _dio;

  ApiClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-User-Id'] = _tempUserId;
          handler.next(options);
        },
        onError: (error, handler) {
          handler.reject(error);
        },
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    required T Function(dynamic json) fromData,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
      );
      return _parseResponse(response, fromData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, dynamic>? data,
    Map<String, String>? extraHeaders,
    required T Function(dynamic json) fromData,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: extraHeaders != null ? Options(headers: extraHeaders) : null,
      );
      return _parseResponse(response, fromData);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Dio get dio => _dio;

  ApiResponse<T> _parseResponse<T>(
    Response response,
    T Function(dynamic json) fromData,
  ) {
    final json = response.data as Map<String, dynamic>;
    final apiResponse = ApiResponse.fromJson(json, fromData);

    if (!apiResponse.success && apiResponse.error != null) {
      throw ApiException.fromApiError(
        apiResponse.error!,
        statusCode: response.statusCode,
      );
    }

    return apiResponse;
  }
}
