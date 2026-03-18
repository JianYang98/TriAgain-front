import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/services/crew_service.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/app_card.dart';

class CrewConfirmScreen extends ConsumerStatefulWidget {
  final String crewId;
  final String? inviteCode;

  const CrewConfirmScreen({
    super.key,
    required this.crewId,
    this.inviteCode,
  });

  @override
  ConsumerState<CrewConfirmScreen> createState() => _CrewConfirmScreenState();
}

class _CrewConfirmScreenState extends ConsumerState<CrewConfirmScreen> {
  bool _isJoining = false;

  Future<void> _handleJoin() async {
    setState(() => _isJoining = true);
    try {
      final crewService = ref.read(crewServiceProvider);
      if (widget.inviteCode != null) {
        await crewService.joinCrew(widget.inviteCode!);
        ref.invalidate(crewByInviteCodeProvider(widget.inviteCode!));
      } else {
        await crewService.joinCrewById(widget.crewId);
        ref.invalidate(crewPreviewProvider(widget.crewId));
      }
      ref.invalidate(crewListProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('가입되었습니다!')),
      );
      if (widget.inviteCode != null) {
        context.go('/home');
      } else {
        context.push('/crew/${widget.crewId}');
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isJoining = false);
    }
  }

  String? _getBlockedMessage(String? reason) {
    return switch (reason) {
      'CREW_FULL' => '정원이 가득 찼습니다',
      'LATE_JOIN_NOT_ALLOWED' => '중간 가입이 허용되지 않는 크루입니다',
      'CREW_ENDED' => '종료된 크루입니다',
      'ALREADY_MEMBER' => '이미 참여 중인 크루입니다',
      'CREW_JOIN_DEADLINE_PASSED' => '참여 마감 기한이 지났습니다',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final crewAsync = widget.inviteCode != null
        ? ref.watch(crewByInviteCodeProvider(widget.inviteCode!))
        : ref.watch(crewPreviewProvider(widget.crewId));

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
                        onPressed: () {
                          if (widget.inviteCode != null) {
                            ref.invalidate(crewByInviteCodeProvider(widget.inviteCode!));
                          } else {
                            ref.invalidate(crewPreviewProvider(widget.crewId));
                          }
                        },
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

        // 하단 버튼
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSizes.paddingMD,
          ),
          child: Column(
            children: [
              _buildBottomButton(context, crew),
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

  Widget _buildBottomButton(BuildContext context, CrewDetail crew) {
    // ALREADY_MEMBER → 크루 상세로 이동
    if (crew.joinBlockedReason == 'ALREADY_MEMBER') {
      return AppButton(
        text: '크루 보기',
        onPressed: () => context.push('/crew/${widget.crewId}'),
      );
    }

    // 가입 불가 사유 있음
    final blockedMessage = _getBlockedMessage(crew.joinBlockedReason);
    if (crew.joinable == false && blockedMessage != null) {
      return AppButton(
        text: blockedMessage,
        onPressed: null,
      );
    }

    // 가입 가능
    if (crew.joinable == true) {
      return AppButton(
        text: '크루 참여하기',
        isLoading: _isJoining,
        onPressed: _handleJoin,
      );
    }

    // fallback (joinable/joinBlockedReason 둘 다 null)
    return AppButton(
      text: '확인',
      onPressed: () => context.go('/home'),
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
