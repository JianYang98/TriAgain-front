import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/features/home/widgets/crew_card.dart';
import 'package:triagain/models/mock_data.dart';
import 'package:triagain/widgets/app_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final crews = MockData.crews;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingLG),
              Text(
                'TriAgain',
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.white,
                ),
              ),
              const SizedBox(height: AppSizes.paddingXS),
              Text(
                'Start Small. Try Again',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.grey3,
                ),
              ),
              const SizedBox(height: AppSizes.paddingLG),
              Expanded(
                child: ListView.separated(
                  itemCount: crews.length,
                  separatorBuilder: (_, _) =>
                      const SizedBox(height: AppSizes.paddingMD),
                  itemBuilder: (context, index) {
                    return CrewCard(
                      crew: crews[index],
                      onTap: () => context.push('/crew/${crews[index].id}'),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
              AppButton(
                text: '+ 크루 만들기',
                onPressed: () => context.push('/crew/create'),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => _showInviteCodeDialog(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.grey1),
                    backgroundColor: AppColors.background,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.buttonRadius),
                    ),
                  ),
                  child: Text(
                    '초대코드',
                    style:
                        AppTextStyles.button.copyWith(color: AppColors.grey4),
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.paddingMD),
            ],
          ),
        ),
      ),
    );
  }

  void _showInviteCodeDialog(BuildContext context) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
          title: Text(
            '초대코드 입력',
            style: AppTextStyles.heading3.copyWith(color: AppColors.white),
          ),
          content: TextField(
            controller: controller,
            style: AppTextStyles.body1.copyWith(color: AppColors.white),
            decoration: InputDecoration(
              hintText: '초대코드를 입력하세요',
              hintStyle: AppTextStyles.body2.copyWith(color: AppColors.grey3),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                borderSide: BorderSide(color: AppColors.grey1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                borderSide: BorderSide(color: AppColors.grey1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                borderSide: BorderSide(color: AppColors.main),
              ),
            ),
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
                final code = controller.text.trim();
                Navigator.of(dialogContext).pop();
                final crew = MockData.findByInviteCode(code);
                if (crew != null) {
                  context.push('/crew/confirm?crewId=${crew.id}');
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('유효하지 않은 초대코드입니다'),
                    ),
                  );
                }
              },
              child: Text(
                '참여하기',
                style: AppTextStyles.body2.copyWith(color: AppColors.main),
              ),
            ),
          ],
        );
      },
    );
  }
}
