import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';

const _inviteCode = 'ABC123';

class CrewSuccessScreen extends StatelessWidget {
  const CrewSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSizes.paddingLG),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('🎉', style: TextStyle(fontSize: 64)),
                const SizedBox(height: AppSizes.paddingMD),
                Text(
                  '크루가 생성됐어요!',
                  style: AppTextStyles.heading1
                      .copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppSizes.paddingSM),
                Text(
                  '친구들을 초대해서 함께 시작해보세요!',
                  style:
                      AppTextStyles.body1.copyWith(color: AppColors.grey3),
                ),
                const SizedBox(height: AppSizes.paddingXL),
                _buildInviteCodeBox(),
                const SizedBox(height: AppSizes.paddingMD),
                _buildButtonRow(context),
                const SizedBox(height: AppSizes.paddingMD),
                _buildStartDateBox(),
                const SizedBox(height: AppSizes.paddingLG),
                TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    '나중에 초대하기 >',
                    style: AppTextStyles.body1
                        .copyWith(color: AppColors.grey3),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInviteCodeBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.grey1),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Center(
        child: Text(
          _inviteCode,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.white,
            letterSpacing: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildButtonRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _copyToClipboard(context),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('코드 복사'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.white,
                side: const BorderSide(color: AppColors.grey1),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.buttonRadius),
                ),
                textStyle: AppTextStyles.button,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _copyToClipboard(context),
              icon: const Icon(Icons.link, size: 18),
              label: const Text('링크 공유'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.main,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(AppSizes.buttonRadius),
                ),
                textStyle: AppTextStyles.button,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStartDateBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingMD),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: AppColors.grey1),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Center(
        child: Text(
          '크루 시작: 2026.02.24',
          style: AppTextStyles.body1.copyWith(color: AppColors.grey4),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(const ClipboardData(text: _inviteCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('초대코드가 복사되었습니다'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
