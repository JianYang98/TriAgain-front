import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/widgets/app_card.dart';

class CrewCard extends StatelessWidget {
  final CrewSummary crew;
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
          Row(
            children: [
              Expanded(
                child: Text(
                  crew.name,
                  style: AppTextStyles.heading3.copyWith(
                    color: AppColors.white,
                  ),
                ),
              ),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            crew.goal,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          Row(
            children: [
              Icon(Icons.people_outline, color: AppColors.grey3, size: 16),
              const SizedBox(width: 4),
              Text(
                '${crew.currentMembers}/${crew.maxMembers}명',
                style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
              ),
              const Spacer(),
              Text(
                '${_formatDate(crew.startDate)} ~ ${_formatDate(crew.endDate)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (color, bgColor) = switch (crew.status) {
      CrewStatus.recruiting => (AppColors.warning, AppColors.warning),
      CrewStatus.active => (AppColors.success, AppColors.success),
      CrewStatus.completed => (AppColors.grey3, AppColors.grey3),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.badgeRadius),
      ),
      child: Text(
        crew.status.label,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
