import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/providers/verification_provider.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/app_card.dart';

class MyVerificationTab extends ConsumerWidget {
  final String crewId;

  const MyVerificationTab({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider(crewId));

    return feedAsync.when(
      data: (feed) {
        final progress = feed.myProgress;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            children: [
              _buildChallengeProgressCard(context, progress),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.main),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '데이터를 불러올 수 없습니다',
              style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
            ),
            const SizedBox(height: AppSizes.paddingSM),
            TextButton(
              onPressed: () => ref.invalidate(feedProvider(crewId)),
              child: Text(
                '다시 시도',
                style: AppTextStyles.body2.copyWith(color: AppColors.main),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeProgressCard(
      BuildContext context, dynamic progress) {
    final completedDays = progress.completedDays as int;
    final targetDays = progress.targetDays as int;
    final challengeId = progress.challengeId as String;

    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingSM),
          // Day dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(targetDays, (index) {
              final isCompleted = index < completedDays;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < targetDays - 1 ? AppSizes.paddingLG : 0,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isCompleted ? AppColors.main : AppColors.grey2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      'Day ${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: isCompleted ? AppColors.white : AppColors.grey3,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            '$completedDays/$targetDays일 완료',
            style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          AppButton(
            text: '📷 오늘 인증하기',
            onPressed: () => context.push(
                '/verification?crewId=$crewId&challengeId=$challengeId'),
          ),
          const SizedBox(height: AppSizes.paddingXS),
        ],
      ),
    );
  }
}
