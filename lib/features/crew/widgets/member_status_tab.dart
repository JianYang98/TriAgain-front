import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/providers/crew_provider.dart';

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
        final members = List<CrewMember>.from(crew.members)..sort(_compareMember);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: AppSizes.paddingSM),
                child: Text(
                  '크루원 (${crew.currentMembers}/${crew.maxMembers})',
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.white),
                ),
              ),
              for (int i = 0; i < members.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSizes.paddingMD),
                _buildMemberRow(members[i],
                    crewStatus: crew.status, isFirst: i == 0),
              ],
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

  int _compareMember(CrewMember a, CrewMember b) {
    if (a.successCount != b.successCount) {
      return b.successCount.compareTo(a.successCount);
    }
    final aJoined = a.joinedAt ?? DateTime(2099);
    final bJoined = b.joinedAt ?? DateTime(2099);
    return aJoined.compareTo(bJoined);
  }

  Widget _buildMemberRow(CrewMember member,
      {required CrewStatus crewStatus, required bool isFirst}) {
    final progress = member.challengeProgress;
    final successCount = member.successCount;
    final completed = progress?.completedDays ?? 0;
    final target = progress?.targetDays ?? 3;
    final isSuccess = progress?.challengeStatus == 'SUCCESS';

    // 크루 상태별 텍스트 분기
    final String attemptText;
    if (crewStatus == CrewStatus.recruiting) {
      attemptText = '아직 크루 시작 전입니다';
    } else if (crewStatus == CrewStatus.completed) {
      attemptText =
          successCount > 0 ? '작심삼일 $successCount회 달성' : '달성 기록 없음';
    } else {
      // ACTIVE
      if (successCount > 0) {
        attemptText = '작심삼일 $successCount회 달성 🔥';
      } else if (progress != null) {
        attemptText = '1번째 작심삼일 달성중';
      } else {
        attemptText = '';
      }
    }

    // 텍스트 색상
    final Color attemptColor;
    if (crewStatus == CrewStatus.recruiting) {
      attemptColor = AppColors.grey3;
    } else if (successCount > 0) {
      attemptColor = AppColors.main;
    } else if (progress != null) {
      attemptColor = AppColors.white;
    } else {
      attemptColor = AppColors.grey3;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 프로필 영역
        SizedBox(
          width: 64,
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.grey2,
                    backgroundImage: member.profileImageUrl != null
                        ? NetworkImage(member.profileImageUrl!)
                        : null,
                    child: member.profileImageUrl == null
                        ? const Icon(
                            Icons.person,
                            color: AppColors.grey3,
                            size: 24,
                          )
                        : null,
                  ),
                  if (isFirst)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: AppColors.main,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.background,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.emoji_events,
                          size: 10,
                          color: AppColors.white,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                member.nickname,
                style: AppTextStyles.caption
                    .copyWith(color: AppColors.grey4),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSizes.paddingSM),
        // 진행 영역
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 2),
              Row(
                children: [
                  if (attemptText.isNotEmpty)
                    Text(
                      attemptText,
                      style: AppTextStyles.body2.copyWith(
                        color: attemptColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  if (member.isLeader) ...[
                    if (attemptText.isNotEmpty)
                      const SizedBox(width: AppSizes.paddingXS),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.main.withValues(alpha: 0.15),
                        borderRadius:
                            BorderRadius.circular(AppSizes.badgeRadius),
                      ),
                      child: Text(
                        '크루장',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.main,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (crewStatus == CrewStatus.recruiting) ...[
                const SizedBox(height: 6),
                Text(
                  '앞으로 작심삼일을 달성해요!',
                  style: AppTextStyles.caption
                      .copyWith(color: AppColors.grey3),
                ),
              ] else ...[
                const SizedBox(height: 6),
                _buildProgressBar(completed, target, isSuccess),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(int completed, int target, bool isSuccess) {
    final fraction = target > 0 ? (completed / target).clamp(0.0, 1.0) : 0.0;

    return SizedBox(
      height: 28,
      child: Stack(
        children: [
          // 배경
          Container(
            decoration: BoxDecoration(
              color: AppColors.grey1,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          // 채움
          if (fraction > 0)
            FractionallySizedBox(
              widthFactor: fraction,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.main,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          // 텍스트
          Positioned(
            right: 10,
            top: 0,
            bottom: 0,
            child: Center(
              child: isSuccess
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Done',
                          style: AppTextStyles.body2.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.check_circle,
                          color: AppColors.white,
                          size: 14,
                        ),
                      ],
                    )
                  : Text(
                      '$completed/$target',
                      style: AppTextStyles.body2.copyWith(
                        color: completed > 0
                            ? AppColors.white
                            : AppColors.grey3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
