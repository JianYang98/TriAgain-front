import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/widgets/app_card.dart';

class SearchCrewCard extends StatelessWidget {
  final SearchCrewItem crew;
  final VoidCallback? onJoin;
  final bool isJoining;

  const SearchCrewCard({
    super.key,
    required this.crew,
    this.onJoin,
    this.isJoining = false,
  });

  String get _categoryEmoji => switch (crew.category) {
        CrewCategory.exercise => '\u{1F4AA}',
        CrewCategory.study => '\u{1F4DA}',
        CrewCategory.lifestyle => '\u{1F331}',
        CrewCategory.selfDev => '\u{1F680}',
        CrewCategory.etc => '\u{2728}',
        null => '',
      };

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 크루 이름 + 카테고리 이모지
          Row(
            children: [
              Expanded(
                child: Text(
                  crew.name,
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (crew.category != null)
                Text(
                  _categoryEmoji,
                  style: const TextStyle(fontSize: 20),
                ),
            ],
          ),
          const SizedBox(height: AppSizes.paddingXS),

          // 목표
          Text(
            crew.goal,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSizes.paddingMD),

          // 인원 + 상태 뱃지
          Row(
            children: [
              const Icon(Icons.people_outline, color: AppColors.grey3, size: 16),
              const SizedBox(width: 4),
              Text(
                '${crew.currentMembers}/${crew.maxMembers}명',
                style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
              ),
              const SizedBox(width: 12),
              _buildStatusBadge(),
            ],
          ),
          const SizedBox(height: AppSizes.paddingSM),

          // 기간 + 참여 버튼
          Row(
            children: [
              Text(
                '${_formatDate(crew.startDate)} ~ ${_formatDate(crew.endDate)}',
                style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
              ),
              const Spacer(),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: isJoining ? null : onJoin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.main,
                    disabledBackgroundColor: AppColors.grey2,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSizes.buttonRadius),
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: isJoining
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.white,
                          ),
                        )
                      : Text(
                          crew.status == CrewStatus.recruiting
                              ? '참여하기'
                              : '합류하기',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.white, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    final (color, label) = switch (crew.status) {
      CrewStatus.recruiting => (AppColors.warning, '모집중'),
      CrewStatus.active => (AppColors.success, '진행중'),
      CrewStatus.completed => (AppColors.grey3, '완료'),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSizes.badgeRadius),
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: color),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day.toString().padLeft(2, '0')}';
  }
}
