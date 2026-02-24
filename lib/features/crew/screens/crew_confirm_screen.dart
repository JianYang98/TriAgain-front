import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/models/mock_data.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/app_card.dart';

class CrewConfirmScreen extends StatelessWidget {
  final String crewId;

  const CrewConfirmScreen({super.key, required this.crewId});

  @override
  Widget build(BuildContext context) {
    final crew = MockData.crews.firstWhere((c) => c.id == crewId);
    final members = MockData.crewMembers;
    final endDate = crew.createdAt.add(Duration(days: 15));
    final remaining = endDate.difference(DateTime.now()).inDays;

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

            // 스크롤 콘텐츠
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
                      '🏃 ${crew.name}',
                      style: AppTextStyles.heading1
                          .copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: AppSizes.paddingLG),

                    // 목표
                    _buildInfoCard('목표', crew.goal),
                    const SizedBox(height: 12),

                    // 기간
                    _buildInfoCard(
                      '기간',
                      '${_formatDate(crew.createdAt)} ~ ${_formatDate(endDate)} ($remaining일 남음)',
                    ),
                    const SizedBox(height: 12),

                    // 인증 방식
                    _buildInfoCard(
                      '인증 방식',
                      crew.verificationType == VerificationType.photoRequired
                          ? '📷 사진 필수'
                          : '✏️ 텍스트만',
                    ),
                    const SizedBox(height: 12),

                    // 중간 가입
                    _buildInfoCard(
                      '중간 가입',
                      crew.allowMidJoin ? '✅ 가능' : '❌ 불가',
                    ),
                    const SizedBox(height: AppSizes.paddingLG),

                    // 크루원 섹션
                    Text(
                      '크루원 (${crew.currentMembers}/${crew.maxMembers})',
                      style: AppTextStyles.heading3
                          .copyWith(color: AppColors.white),
                    ),
                    const SizedBox(height: AppSizes.paddingSM),
                    AppCard(
                      child: Column(
                        children: members
                            .map((m) => _buildMemberRow(
                                  m['name'] as String,
                                  m['isLeader'] as bool,
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingLG),
                  ],
                ),
              ),
            ),

            // 하단 버튼
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMD,
              ),
              child: Column(
                children: [
                  AppButton(
                    text: '크루 참여하기! 🚀',
                    onPressed: () {
                      if (crew.currentMembers >= crew.maxMembers) {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.card,
                            content: Text(
                              '정원이 다찼습니다.',
                              style: AppTextStyles.body1
                                  .copyWith(color: AppColors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('확인',
                                    style: TextStyle(color: AppColors.main)),
                              ),
                            ],
                          ),
                        );
                      } else {
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: AppColors.card,
                            content: Text(
                              '크루에 가입되었습니다!',
                              style: AppTextStyles.body1
                                  .copyWith(color: AppColors.white),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.go('/home');
                                },
                                child: Text('확인',
                                    style: TextStyle(color: AppColors.main)),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                  ),
                  TextButton(
                    onPressed: () => context.pop(),
                    child: Text(
                      '나중에',
                      style: AppTextStyles.body1
                          .copyWith(color: AppColors.grey3),
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingSM),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildMemberRow(String name, bool isLeader) {
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
            name,
            style: AppTextStyles.body1.copyWith(color: AppColors.white),
          ),
          if (isLeader) ...[
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
