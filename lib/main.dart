import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:triagain/app/router.dart';
import 'package:triagain/app/theme.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/services/auth_service.dart';

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
        initialLocation = '/home';
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
