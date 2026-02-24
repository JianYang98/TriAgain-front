import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/widgets/app_card.dart';

class CrewCard extends StatelessWidget {
  final Crew crew;
  final VoidCallback? onTap;

  const CrewCard({
    super.key,
    required this.crew,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            crew.name,
            style: AppTextStyles.heading3.copyWith(
              color: AppColors.white,
            ),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            crew.goal,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          _buildProgressBar(),
          const SizedBox(height: AppSizes.paddingSM),
          Row(
            children: [
              Text(
                'Day ${crew.currentDay}/3',
                style: AppTextStyles.body2.copyWith(color: AppColors.white),
              ),
              const Spacer(),
              _buildRoundBadge(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Container(
            height: 6,
            margin: EdgeInsets.only(right: index < 2 ? 6 : 0),
            decoration: BoxDecoration(
              color: index < crew.currentDay
                  ? AppColors.main
                  : AppColors.grey2,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildRoundBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.main.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.badgeRadius),
      ),
      child: Text(
        '작심삼일 ${crew.round}번째 🔥',
        style: AppTextStyles.caption.copyWith(color: AppColors.main),
      ),
    );
  }
}
