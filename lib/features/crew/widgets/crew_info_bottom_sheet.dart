import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/widgets/app_card.dart';

class CrewInfoBottomSheet extends StatelessWidget {
  final CrewDetail crew;

  const CrewInfoBottomSheet({super.key, required this.crew});

  @override
  Widget build(BuildContext context) {
    final remaining = crew.endDate.difference(DateTime.now()).inDays;

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
                    crew.name,
                    style: AppTextStyles.heading1.copyWith(
                      color: AppColors.white,
                    ),
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
                  if (crew.deadlineTime != null) ...[
                    const SizedBox(height: 12),
                    _buildInfoCard(
                      '인증 마감',
                      '${_formatDeadlineLabel(crew.deadlineTime!)}까지',
                    ),
                  ],
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
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: crew.inviteCode ?? ''),
                        );
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(context).pop();
                        messenger.showSnackBar(
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
                const SizedBox(width: AppSizes.paddingSM),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        final message =
                            '🔥 TriAgain 크루에 초대합니다!\n크루: ${crew.name}\n초대코드: ${crew.inviteCode}';
                        SharePlus.instance.share(ShareParams(text: message));
                      },
                      icon: const Icon(Icons.share, size: 18),
                      label: const Text('초대 메시지 공유'),
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

  Widget _buildMemberRow(CrewMember member) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingXS),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
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
          const SizedBox(width: 12),
          Text(
            member.nickname,
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

  String _formatDeadlineLabel(String deadlineTime) {
    final parts = deadlineTime.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    final period = hour < 12 ? '오전' : '오후';
    final displayHour = hour == 0 ? 12 : hour > 12 ? hour - 12 : hour;
    final minuteStr = minute > 0 ? ' $minute분' : '';
    return '$period $displayHour시$minuteStr';
  }

  String _formatDate(DateTime date) {
    return '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
  }
}
