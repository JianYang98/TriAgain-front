import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kakao_flutter_sdk/kakao_flutter_sdk.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/models/auth.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/services/auth_service.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
          child: Column(
            children: [
              const Spacer(flex: 3),
              Image.asset(
                'images/logo.png',
                width: 100,
                height: 100,
              ),
              const SizedBox(height: 24),
              Text(
                'TriAgain',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Start Small. Try Again.',
                style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
              ),
              const Spacer(flex: 4),
              // 카카오 로그인 버튼 (항상 표시)
              GestureDetector(
                onTap: () => _loginWithKakao(context, ref),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'images/kakao/kakao_login.png',
                    width: double.infinity,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              // Apple 로그인 버튼 (iOS만)
              if (Platform.isIOS) ...[
                const SizedBox(height: AppSizes.paddingSM),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: SignInWithAppleButton(
                    text: 'Apple로 로그인',
                    style: SignInWithAppleButtonStyle.white,
                    // TODO: Apple Developer 승인 후 _loginWithApple(context, ref) 로 복원
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Apple 로그인은 준비중입니다.'),
                        ),
                      );
                    },
                  ),
                ),
              ],
              if (!kReleaseMode) ...[
                const SizedBox(height: AppSizes.paddingSM),
                _buildTestUserButton(
                  context,
                  ref,
                  label: 'Test User 1',
                  userId: 'test-user-1',
                ),
                const SizedBox(height: AppSizes.paddingSM),
                _buildTestUserButton(
                  context,
                  ref,
                  label: 'Test User 2',
                  userId: 'test-user-2',
                ),
                const SizedBox(height: AppSizes.paddingSM),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => _showCustomLoginDialog(context, ref),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.grey3),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.buttonRadius),
                      ),
                      textStyle: AppTextStyles.button,
                    ),
                    child: Text(
                      '커스텀 로그인',
                      style:
                          AppTextStyles.button.copyWith(color: AppColors.grey4),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSizes.paddingXL),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loginWithKakao(BuildContext context, WidgetRef ref) async {
    try {
      // 1. 카카오 SDK 로그인 → kakaoAccessToken 획득
      OAuthToken token;
      if (await isKakaoTalkInstalled()) {
        token = await UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await UserApi.instance.loginWithKakaoAccount();
      }

      final kakaoAccessToken = token.accessToken;
      debugPrint('카카오 로그인 성공: $kakaoAccessToken');

      // 2. POST /auth/kakao 호출
      final authService = ref.read(authServiceProvider);
      final result = await authService.loginWithKakao(kakaoAccessToken); // 카카오 토큰 받음 

      if (!context.mounted) return;

      if (!result.isNewUser) { // 기존 유저일때! 
        // 3. 기존 유저 → 토큰 저장 → 홈 이동
        ref.read(authTokenProvider.notifier).state = result.accessToken;
        ref.read(authUserIdProvider.notifier).state = result.user!.id;
        ref.read(authUserProvider.notifier).state = result.user;

        // refreshToken → SecureStorage 저장
        final storage = ref.read(secureStorageProvider);
        await saveRefreshToken(storage, result.refreshToken!);

        // 크루 캐시 초기화 — 유저 전환 시 이전 데이터 방지
        ref.invalidate(crewListProvider);

        debugPrint('로그인 완료: userId=${result.user!.id}');

        if (!context.mounted) return;
        context.go('/home'); // 홈으로 
      } else {
        // 4. 신규 유저 → 임시 저장 → 온보딩 이동
        ref.read(kakaoAccessTokenProvider.notifier).state = kakaoAccessToken;
        ref.read(kakaoIdProvider.notifier).state = result.kakaoId;
        ref.read(kakaoProfileProvider.notifier).state = result.kakaoProfile;

        context.go('/onboarding');
      }
    } on ApiException catch (e) {
      debugPrint('백엔드 인증 실패: ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (error) {
      debugPrint('카카오 로그인 실패: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('로그인에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ignore: unused_element
  Future<void> _loginWithApple(BuildContext context, WidgetRef ref) async {
    try {
      // 1. Apple SDK 로그인
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) throw Exception('identityToken is null');

      debugPrint('Apple 로그인 성공: identityToken 획득');

      // 2. POST /auth/apple 호출
      final authService = ref.read(authServiceProvider);
      final result = await authService.loginWithApple(identityToken);

      if (!context.mounted) return;

      if (!result.isNewUser) {
        // 3. 기존 유저 → 토큰 저장 → 홈
        ref.read(authTokenProvider.notifier).state = result.accessToken;
        ref.read(authUserIdProvider.notifier).state = result.user!.id;
        ref.read(authUserProvider.notifier).state = result.user;

        final storage = ref.read(secureStorageProvider);
        await saveRefreshToken(storage, result.refreshToken!);

        ref.invalidate(crewListProvider);

        debugPrint('Apple 로그인 완료: userId=${result.user!.id}');

        if (!context.mounted) return;
        context.go('/home');
      } else {
        // 4. 신규 유저 → Apple 임시 저장 → 온보딩
        ref.read(appleIdentityTokenProvider.notifier).state = identityToken;
        ref.read(appleUserIdProvider.notifier).state = result.appleId;

        // Apple은 이름을 최초 1회만 제공
        final givenName = credential.givenName ?? '';
        final familyName = credential.familyName ?? '';
        final nickname = '$familyName$givenName'.trim();
        ref.read(appleProfileProvider.notifier).state = KakaoProfile(
          nickname: nickname.isNotEmpty ? nickname : '',
          email: result.email ?? credential.email,
        );

        context.go('/onboarding');
      }
    } on ApiException catch (e) {
      debugPrint('Apple 백엔드 인증 실패: ${e.code} - ${e.message}');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (error) {
      debugPrint('Apple 로그인 실패: $error');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Apple 로그인에 실패했습니다. 다시 시도해주세요.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showCustomLoginDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          '커스텀 로그인',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.body1.copyWith(color: AppColors.white),
          decoration: InputDecoration(
            hintText: 'userId 입력',
            hintStyle: AppTextStyles.body1.copyWith(color: AppColors.grey3),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.grey2),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.main),
            ),
          ),
          onSubmitted: (value) {
            if (value.trim().isNotEmpty) {
              Navigator.of(dialogContext).pop();
              _loginAsTestUser(context, ref, value.trim());
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              '취소',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
            ),
          ),
          TextButton(
            onPressed: () {
              final value = controller.text.trim();
              if (value.isNotEmpty) {
                Navigator.of(dialogContext).pop();
                _loginAsTestUser(context, ref, value);
              }
            },
            child: Text(
              '확인',
              style: AppTextStyles.body2.copyWith(color: AppColors.main),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loginAsTestUser(
      BuildContext context, WidgetRef ref, String userId) async {
    try {
      final authService = ref.read(authServiceProvider);
      final result = await authService.testLogin(userId);

      // null 방어 — test-login은 항상 기존 유저, 3개 필드 필수
      if (result.accessToken == null ||
          result.refreshToken == null ||
          result.user == null) {
        throw Exception('Invalid test login response');
      }

      if (!context.mounted) return;

      // 토큰 세팅 (카카오 로그인과 동일)
      ref.read(authTokenProvider.notifier).state = result.accessToken;
      ref.read(authUserIdProvider.notifier).state = result.user!.id;
      ref.read(authUserProvider.notifier).state = result.user;

      final storage = ref.read(secureStorageProvider);
      await saveRefreshToken(storage, result.refreshToken!);

      // 크루 캐시 초기화 — 유저 전환 시 이전 데이터 방지
      ref.invalidate(crewListProvider);

      debugPrint('테스트 로그인 완료: userId=${result.user!.id}');

      if (!context.mounted) return;
      context.go('/home');
    } on ApiException catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      debugPrint('테스트 로그인 실패: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('테스트 로그인에 실패했습니다.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildTestUserButton(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String userId,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: () => _loginAsTestUser(context, ref, userId),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.main,
          foregroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
          ),
          textStyle: AppTextStyles.button,
        ),
        child: Text(label),
      ),
    );
  }
}
