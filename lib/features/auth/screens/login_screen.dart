import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/constants/app_sizes.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.go('/home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFEE500),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
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
}
