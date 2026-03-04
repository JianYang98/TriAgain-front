import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/services/auth_service.dart';
import 'api_exception.dart';
import 'api_response.dart';

const _baseUrl = 'http://localhost:8080';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(ref: ref);
});

class ApiClient {
  late final Dio _dio;
  final Ref _ref;
  bool _isRefreshing = false;

  ApiClient({required Ref ref}) : _ref = ref {
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
          if (!options.path.startsWith('/auth/')) {
            final token = _ref.read(authTokenProvider);
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.startsWith('/auth/') &&
              !_isRefreshing) {
            _isRefreshing = true;
            try {
              final authService = _ref.read(authServiceProvider);
              final newToken = await authService.refreshAccessToken();

              if (newToken != null) {
                _ref.read(authTokenProvider.notifier).state = newToken;

                // 원래 요청 재시도
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newToken';
                final response = await _dio.fetch(opts);
                return handler.resolve(response);
              }
            } catch (_) {
              // refresh 실패 — 아래에서 로그아웃 처리
            } finally {
              _isRefreshing = false;
            }

            // refresh 실패 → 로그아웃
            _ref.read(authTokenProvider.notifier).state = null;
            _ref.read(authUserIdProvider.notifier).state = null;
            _ref.read(authUserProvider.notifier).state = null;
            final storage = _ref.read(secureStorageProvider);
            await deleteRefreshToken(storage);
            _ref.invalidate(crewListProvider);
          }
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

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Map<String, dynamic>? data,
    required T Function(dynamic json) fromData,
  }) async {
    try {
      final response = await _dio.patch(
        path,
        data: data,
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
