import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/app_card.dart';

class CrewConfirmScreen extends ConsumerWidget {
  final String crewId;

  const CrewConfirmScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crewAsync = ref.watch(crewDetailProvider(crewId));

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 헤더
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMD,
                vertical: AppSizes.paddingSM,
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: const Icon(
                      Icons.arrow_back,
                      color: AppColors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '크루 확인',
                    style: AppTextStyles.heading1
                        .copyWith(color: AppColors.white),
                  ),
                ],
              ),
            ),

            Expanded(
              child: crewAsync.when(
                data: (crew) => _buildContent(context, crew),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.main),
                ),
                error: (error, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '크루 정보를 불러올 수 없습니다',
                        style: AppTextStyles.body1
                            .copyWith(color: AppColors.grey3),
                      ),
                      const SizedBox(height: AppSizes.paddingSM),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(crewDetailProvider(crewId)),
                        child: Text(
                          '다시 시도',
                          style: AppTextStyles.body2
                              .copyWith(color: AppColors.main),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, CrewDetail crew) {
    final remaining = crew.endDate.difference(DateTime.now()).inDays;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingMD,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSizes.paddingMD),
                Text(
                  crew.name,
                  style: AppTextStyles.heading1
                      .copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppSizes.paddingLG),

                _buildInfoCard('목표', crew.goal),
                const SizedBox(height: 12),

                _buildInfoCard(
                  '기간',
                  '${_formatDate(crew.startDate)} ~ ${_formatDate(crew.endDate)} ($remaining일 남음)',
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  '인증 방식',
                  crew.verificationType == VerificationType.photo
                      ? '📷 사진 필수'
                      : '✏️ 텍스트만',
                ),
                const SizedBox(height: 12),

                _buildInfoCard(
                  '중간 가입',
                  crew.allowLateJoin ? '✅ 가능' : '❌ 불가',
                ),
                const SizedBox(height: AppSizes.paddingLG),

                Text(
                  '크루원 (${crew.currentMembers}/${crew.maxMembers})',
                  style: AppTextStyles.heading3
                      .copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppSizes.paddingSM),
                AppCard(
                  child: Column(
                    children: crew.members
                        .map((m) => _buildMemberRow(m))
                        .toList(),
                  ),
                ),
                const SizedBox(height: AppSizes.paddingLG),
              ],
            ),
          ),
        ),

        // 하단 버튼 — 이미 join 완료 상태이므로 홈으로 이동
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMD,
          ),
          child: Column(
            children: [
              AppButton(
                text: '시작하기! 🚀',
                onPressed: () => context.go('/home'),
              ),
              TextButton(
                onPressed: () => context.go('/home'),
                child: Text(
                  '홈으로',
                  style: AppTextStyles.body1
                      .copyWith(color: AppColors.grey3),
                ),
              ),
              const SizedBox(height: AppSizes.paddingSM),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            value,
            style: AppTextStyles.body1.copyWith(color: AppColors.white),
          ),
        ],
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
            child: Icon(
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

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
