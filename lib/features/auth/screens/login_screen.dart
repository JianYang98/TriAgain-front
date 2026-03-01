import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/providers/auth_provider.dart';

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
              if (kDebugMode) ...[
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
              ] else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: 카카오 로그인 구현
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFEE500),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSizes.buttonRadius),
                      ),
                      textStyle: AppTextStyles.button,
                    ),
                    child: const Text('카카오로 시작하기'),
                  ),
                ),
              const SizedBox(height: AppSizes.paddingXL),
            ],
          ),
        ),
      ),
    );
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
        onPressed: () {
          ref.read(authUserIdProvider.notifier).state = userId;
          context.go('/home');
        },
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
