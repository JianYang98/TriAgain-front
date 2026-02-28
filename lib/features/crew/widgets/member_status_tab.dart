import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/widgets/app_card.dart';

class MemberStatusTab extends ConsumerWidget {
  final String crewId;

  const MemberStatusTab({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crewAsync = ref.watch(crewDetailProvider(crewId));

    return crewAsync.when(
      data: (crew) {
        final members = crew.members;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '크루원 (${crew.currentMembers}/${crew.maxMembers})',
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppSizes.paddingMD),
                ...members.map((m) => _buildMemberRow(m)),
              ],
            ),
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
              onPressed: () =>
                  ref.invalidate(crewDetailProvider(crewId)),
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

  Widget _buildMemberRow(CrewMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.grey2,
            child: const Icon(
              Icons.person,
              color: AppColors.grey3,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            member.userId,
            style: AppTextStyles.body1.copyWith(color: AppColors.white),
          ),
          if (member.isLeader) ...[
            const SizedBox(width: AppSizes.paddingSM),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingSM,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.main,
                borderRadius: BorderRadius.circular(AppSizes.badgeRadius),
              ),
              child: Text(
                '크루장',
                style: AppTextStyles.caption.copyWith(color: AppColors.white),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
