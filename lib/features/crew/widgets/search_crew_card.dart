import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/widgets/app_card.dart';

class SearchCrewCard extends StatelessWidget {
  final SearchCrewItem crew;
  final VoidCallback? onTap;

  const SearchCrewCard({
    super.key,
    required this.crew,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 크루 이름
            Text(
              crew.name,
              style: AppTextStyles.heading3.copyWith(color: AppColors.white),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.paddingXS),

            // 목표
            Text(
              crew.goal,
              style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSizes.paddingSM),

            // [카테고리] · 👤 인원 · 상태 · 기간
            Row(
              children: [
                if (crew.category != null) ...[
                  _buildCategoryTag(),
                  _buildDot(),
                ],
                const Icon(Icons.people_outline,
                    color: AppColors.grey3, size: 14),
                const SizedBox(width: 2),
                Text(
                  '${crew.currentMembers}/${crew.maxMembers}명',
                  style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
                ),
                _buildDot(),
                _buildStatusText(),
                _buildDot(),
                Flexible(
                  child: Text(
                    '${_formatDate(crew.startDate)}~${_formatDate(crew.endDate)}',
                    style:
                        AppTextStyles.caption.copyWith(color: AppColors.grey3),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTag() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.badgeRadius),
        border: Border.all(color: AppColors.main),
      ),
      child: Text(
        crew.category!.label,
        style: AppTextStyles.caption
            .copyWith(color: AppColors.main, fontSize: 11),
      ),
    );
  }

  Widget _buildDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        '\u{00B7}',
        style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
      ),
    );
  }

  Widget _buildStatusText() {
    final (color, label) = switch (crew.status) {
      CrewStatus.recruiting => (AppColors.warning, '모집중'),
      CrewStatus.active => (AppColors.success, '진행중'),
      CrewStatus.completed => (AppColors.grey3, '완료'),
    };

    return Text(
      label,
      style: AppTextStyles.caption.copyWith(color: color),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day.toString().padLeft(2, '0')}';
  }
}
