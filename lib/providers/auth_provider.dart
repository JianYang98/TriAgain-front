import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:triagain/models/auth.dart';

// 기존 유지 (하위 호환)
final authUserIdProvider = StateProvider<String?>((ref) => null);

// JWT accessToken — 메모리만! SecureStorage 저장 금지
final authTokenProvider = StateProvider<String?>((ref) => null);

// 유저 정보
final authUserProvider = StateProvider<AuthUser?>((ref) => null);

// 온보딩용 임시 저장 — signup 완료 후 즉시 null 처리!
// kakaoAccessToken: SecureStorage 저장 절대 금지
final kakaoAccessTokenProvider = StateProvider<String?>((ref) => null);
final kakaoIdProvider = StateProvider<String?>((ref) => null);
final kakaoProfileProvider = StateProvider<KakaoProfile?>((ref) => null);

// SecureStorage
const _refreshTokenKey = 'refresh_token';

final secureStorageProvider = Provider<FlutterSecureStorage>((_) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
});

// refreshToken 읽기
Future<String?> readRefreshToken(FlutterSecureStorage storage) async {
  return storage.read(key: _refreshTokenKey);
}

// refreshToken 저장
Future<void> saveRefreshToken(
    FlutterSecureStorage storage, String token) async {
  await storage.write(key: _refreshTokenKey, value: token);
}

// refreshToken 삭제 (로그아웃)
Future<void> deleteRefreshToken(FlutterSecureStorage storage) async {
  await storage.delete(key: _refreshTokenKey);
}
