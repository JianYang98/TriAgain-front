import 'package:dio/dio.dart';
import 'api_response.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromApiError(ApiError error, {int? statusCode}) {
    return ApiException(
      code: error.code,
      message: error.message,
      statusCode: statusCode,
    );
  }

  factory ApiException.fromDioException(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          code: 'TIMEOUT',
          message: '서버 응답이 너무 느립니다. 다시 시도해주세요.',
        );
      case DioExceptionType.connectionError:
        return const ApiException(
          code: 'CONNECTION_ERROR',
          message: '서버에 연결할 수 없습니다. 네트워크를 확인해주세요.',
        );
      case DioExceptionType.badResponse:
        final response = e.response;
        if (response != null && response.data is Map<String, dynamic>) {
          final data = response.data as Map<String, dynamic>;
          final error = data['error'];
          if (error is Map<String, dynamic>) {
            return ApiException(
              code: error['code'] as String? ?? 'UNKNOWN',
              message: error['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
              statusCode: response.statusCode,
            );
          }
        }
        return ApiException(
          code: 'HTTP_${response?.statusCode ?? 0}',
          message: '서버 오류가 발생했습니다. (${response?.statusCode})',
          statusCode: response?.statusCode,
        );
      default:
        return const ApiException(
          code: 'UNKNOWN',
          message: '알 수 없는 오류가 발생했습니다.',
        );
    }
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isConflict => statusCode == 409;

  @override
  String toString() => 'ApiException($code): $message';
}
