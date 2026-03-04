import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:triagain/app/router.dart';
import 'package:triagain/app/theme.dart';
import 'package:triagain/core/network/api_client.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/services/auth_service.dart';
import 'package:triagain/services/user_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const kakaoKey = String.fromEnvironment('KAKAO_NATIVE_KEY');
  if (kakaoKey.isEmpty) {
    debugPrint('⚠️ KAKAO_NATIVE_KEY not provided. Kakao login will not work.');
  }
  KakaoSdk.init(nativeAppKey: kakaoKey);

  final container = ProviderContainer();

  // 자동 로그인: SecureStorage에서 refreshToken 복원 시도
  String initialLocation = '/login';
  try {
    final storage = container.read(secureStorageProvider);
    final refreshToken = await readRefreshToken(storage);

    if (refreshToken != null) {
      final authService = container.read(authServiceProvider);
      final newAccessToken = await authService.refreshAccessToken();

      if (newAccessToken != null) {
        container.read(authTokenProvider.notifier).state = newAccessToken;

        // /users/me 호출 → authUser, authUserId 동기화
        try {
          final apiClient = container.read(apiClientProvider);
          final userService = UserService(apiClient);
          final user = await userService.getMe();
          container.read(authUserIdProvider.notifier).state = user.id;
          container.read(authUserProvider.notifier).state = user;
          initialLocation = '/home';
          debugPrint('자동 로그인 성공: userId=${user.id}');
        } catch (_) {
          // /users/me 실패 → 토큰 무효화, 로그인 화면으로
          debugPrint('자동 로그인 실패: /users/me 호출 실패');
          container.read(authTokenProvider.notifier).state = null;
          await deleteRefreshToken(storage);
        }
      }
    }
  } catch (_) {
    // refresh 실패 → 로그인 화면으로
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: TriAgainApp(initialLocation: initialLocation),
    ),
  );
}

class TriAgainApp extends StatelessWidget {
  final String initialLocation;

  const TriAgainApp({super.key, required this.initialLocation});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TriAgain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      routerConfig: createRouter(initialLocation: initialLocation),
    );
  }
}
