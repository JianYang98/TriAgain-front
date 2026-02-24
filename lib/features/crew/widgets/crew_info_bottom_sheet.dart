import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/challenge.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/models/mock_data.dart';
import 'package:triagain/widgets/app_card.dart';

class CrewInfoBottomSheet extends StatelessWidget {
  final Crew crew;

  const CrewInfoBottomSheet({super.key, required this.crew});

  @override
  Widget build(BuildContext context) {
    final activeChallenge = MockData.challenges.where(
      (c) =>
          c.crewId == crew.id &&
          c.status == ChallengeStatus.inProgress,
    );
    final endDate = activeChallenge.isNotEmpty
        ? activeChallenge.first.endDate
        : crew.createdAt.add(Duration(days: crew.durationDays));
    final startDate = activeChallenge.isNotEmpty
        ? activeChallenge.first.startDate
        : crew.createdAt;
    final remaining = endDate.difference(DateTime.now()).inDays;
    final members = MockData.crewMembers;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1E),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.grey2,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMD,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSizes.paddingSM),
                  Text(
                    '🏃 ${crew.name}',
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: AppSizes.paddingLG),

                  _buildInfoCard('목표', crew.goal),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    '기간',
                    '${_formatDate(startDate)} ~ ${_formatDate(endDate)} ($remaining일 남음)',
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    '인증 방식',
                    crew.verificationType == VerificationType.photoRequired
                        ? '📷 사진 필수'
                        : '✏️ 텍스트만',
                  ),
                  const SizedBox(height: 12),

                  _buildInfoCard(
                    '중간 가입',
                    crew.allowMidJoin ? '✅ 가능' : '❌ 불가',
                  ),
                  const SizedBox(height: AppSizes.paddingLG),

                  Text(
                    '크루원 (${crew.currentMembers}/${crew.maxMembers})',
                    style: AppTextStyles.heading3.copyWith(
                      color: AppColors.white,
                    ),
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

          // Fixed bottom buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingMD,
              AppSizes.paddingSM,
              AppSizes.paddingMD,
              AppSizes.paddingLG,
            ),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('링크가 복사되었습니다'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.link, size: 18),
                      label: const Text('링크 공유'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.main,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.buttonRadius,
                          ),
                        ),
                        textStyle: AppTextStyles.button,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSizes.paddingSM),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: crew.inviteCode),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('초대코드가 복사되었습니다'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('코드 복사'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.white,
                        side: const BorderSide(color: AppColors.grey1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSizes.buttonRadius,
                          ),
                        ),
                        textStyle: AppTextStyles.button,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            child: const Icon(
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
