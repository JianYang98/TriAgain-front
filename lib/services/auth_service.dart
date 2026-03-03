import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/models/auth.dart';
import 'package:triagain/providers/auth_provider.dart';

const _baseUrl = 'http://localhost:8080';

final authServiceProvider = Provider<AuthService>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return AuthService(storage: storage);
});

class AuthService {
  final FlutterSecureStorage storage;
  late final Dio _dio;

  AuthService({required this.storage}) {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  /// POST /auth/kakao — 카카오 로그인
  Future<KakaoLoginResponse> loginWithKakao(String kakaoAccessToken) async {
    try {
      final response = await _dio.post(
        '/auth/kakao',
        data: {'kakaoAccessToken': kakaoAccessToken},
      );
      return _parseData(response, KakaoLoginResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /auth/signup — 회원가입
  Future<SignupResponse> signup({
    required String kakaoAccessToken,
    required String kakaoId,
    required String nickname,
    required bool termsAgreed,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/signup',
        data: {
          'kakaoAccessToken': kakaoAccessToken,
          'kakaoId': kakaoId,
          'nickname': nickname,
          'termsAgreed': termsAgreed,
        },
      );
      return _parseData(response, SignupResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /auth/refresh — 토큰 갱신
  /// 성공 시 새 accessToken 반환, 실패 시 null (refreshToken 삭제)
  Future<String?> refreshAccessToken() async {
    final refreshToken = await readRefreshToken(storage);
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final json = response.data as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>;
      return data['accessToken'] as String;
    } on DioException catch (e) {
      debugPrint('토큰 갱신 실패: $e');
      await deleteRefreshToken(storage);
      return null;
    }
  }

  /// POST /auth/test-login — 테스트 로그인 (dev 전용)
  Future<KakaoLoginResponse> testLogin(String userId) async {
    try {
      final response = await _dio.post(
        '/auth/test-login',
        data: {'userId': userId},
      );
      return _parseData(response, KakaoLoginResponse.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// POST /auth/logout — 로그아웃 (best-effort)
  /// 자체 Dio 사용 — 401 refresh→retry 무한루프 방지
  Future<void> logout() async {
    final refreshToken = await readRefreshToken(storage);
    if (refreshToken == null) return;

    try {
      await _dio.post(
        '/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // best-effort: 서버 실패해도 무시
      debugPrint('로그아웃 서버 호출 실패 (무시)');
    }
  }

  T _parseData<T>(Response response, T Function(Map<String, dynamic>) fromJson) {
    final json = response.data as Map<String, dynamic>;
    final status = json['status'] as String?;

    if (status == 'ERROR') {
      final error = json['error'] as Map<String, dynamic>?;
      throw ApiException(
        code: error?['code'] as String? ?? 'UNKNOWN',
        message: error?['message'] as String? ?? '알 수 없는 오류가 발생했습니다.',
        statusCode: response.statusCode,
      );
    }

    final data = json['data'] as Map<String, dynamic>;
    return fromJson(data);
  }
}
