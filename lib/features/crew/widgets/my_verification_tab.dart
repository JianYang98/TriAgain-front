import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/features/crew/widgets/verification_calendar.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/models/verification.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/providers/verification_provider.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/app_card.dart';

class MyVerificationTab extends ConsumerStatefulWidget {
  final String crewId;

  const MyVerificationTab({
    super.key,
    required this.crewId,
  });

  @override
  ConsumerState<MyVerificationTab> createState() => _MyVerificationTabState();
}

class _MyVerificationTabState extends ConsumerState<MyVerificationTab> {
  late final ConfettiController _confettiController;
  bool _justVerified = false;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String get crewId => widget.crewId;

  @override
  Widget build(BuildContext context) {
    final crewAsync = ref.watch(crewDetailProvider(crewId));

    final crew = crewAsync.valueOrNull;
    if (crew == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.main),
      );
    }

    final content = switch (crew.status) {
      CrewStatus.recruiting => _buildRecruitingUI(crew),
      CrewStatus.active => _buildActiveUI(context, crew),
      CrewStatus.completed => _buildCompletedUI(context, crew),
    };

    return Stack(
      children: [
        content,
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            blastDirection: -3.14159 / 2,
            gravity: 0.2,
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            shouldLoop: false,
            colors: const [
              AppColors.main,
              AppColors.mainLight,
              AppColors.mainDark,
              AppColors.success,
              AppColors.warning,
              Colors.white,
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecruitingUI(CrewDetail crew) {
    final startDate = crew.startDate;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.schedule, color: AppColors.grey3, size: 48),
          const SizedBox(height: AppSizes.paddingMD),
          Text(
            '크루 시작 전입니다',
            style: AppTextStyles.heading3.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            '${startDate.month}월 ${startDate.day}일부터 시작해요',
            style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveUI(BuildContext context, CrewDetail crew) {
    final myVerAsync = ref.watch(myVerificationsProvider(crewId));

    return myVerAsync.when(
      data: (myVer) {
        final progress = myVer.myProgress;
        final verifiedDates = myVer.verifiedDatesSet;
        final userId = ref.watch(authUserIdProvider);
        final joinedAt = _findJoinedAt(crew, userId);

        // 방금 인증 완료 + 작심삼일 달성 → 컨페티 재생
        final justCompleted = _justVerified &&
            ((progress != null && progress.status == 'SUCCESS') ||
                (progress == null && myVer.completedChallenges > 0));
        if (justCompleted) {
          _justVerified = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _confettiController.play();
          });
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            children: [
              VerificationCalendar(
                crewStartDate: crew.startDate,
                crewEndDate: crew.endDate,
                verifiedDates: verifiedDates,
                joinedAt: joinedAt,
              ),
              const SizedBox(height: AppSizes.paddingSM),
              _buildStreakSummary(myVer, progress, verifiedDates),
              const SizedBox(height: AppSizes.paddingMD),
              if (progress != null)
                _buildChallengeProgressCard(context, progress, verifiedDates, crew)
              else
                _buildEmptyChallengeCard(
                    context, verifiedDates, crew, myVer.completedChallenges),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.main),
      ),
      error: (error, _) => _buildErrorUI(),
    );
  }

  Widget _buildCompletedUI(BuildContext context, CrewDetail crew) {
    final myVerAsync = ref.watch(myVerificationsProvider(crewId));

    return myVerAsync.when(
      data: (myVer) {
        final progress = myVer.myProgress;
        final verifiedDates = myVer.verifiedDatesSet;
        final userId = ref.watch(authUserIdProvider);
        final joinedAt = _findJoinedAt(crew, userId);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            children: [
              VerificationCalendar(
                crewStartDate: crew.startDate,
                crewEndDate: crew.endDate,
                verifiedDates: verifiedDates,
                joinedAt: joinedAt,
              ),
              const SizedBox(height: AppSizes.paddingSM),
              _buildStreakSummary(myVer, progress, verifiedDates),
              const SizedBox(height: AppSizes.paddingMD),
              AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  child: Text(
                    '크루가 종료되었습니다',
                    style:
                        AppTextStyles.body2.copyWith(color: AppColors.grey3),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.main),
      ),
      error: (error, _) => _buildErrorUI(),
    );
  }

  Widget _buildErrorUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '데이터를 불러올 수 없습니다',
            style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          TextButton(
            onPressed: () {
              ref.invalidate(myVerificationsProvider(crewId));
            },
            child: Text(
              '다시 시도',
              style: AppTextStyles.body2.copyWith(color: AppColors.main),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _findJoinedAt(CrewDetail crew, String? userId) {
    DateTime joinedAt = crew.startDate;
    if (userId != null) {
      for (final m in crew.members) {
        if (m.userId == userId && m.joinedAt != null) {
          joinedAt = DateTime(
            m.joinedAt!.year,
            m.joinedAt!.month,
            m.joinedAt!.day,
          );
          break;
        }
      }
    }
    return joinedAt;
  }

  Widget _buildStreakSummary(
    MyVerificationsResult myVer,
    MyProgress? progress,
    Set<DateTime> verifiedDates,
  ) {
    final completedChallenges = myVer.completedChallenges;
    final completedDays = progress?.completedDays ?? 0;
    final targetDays = progress?.targetDays ?? 3;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isTodayVerified = verifiedDates.contains(today);

    final isAchieved = progress?.status == 'SUCCESS' ||
        (progress == null && completedChallenges > 0 && isTodayVerified);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS),
      child: Row(
        children: [
          Text(
            '작심삼일 $completedChallenges회 달성',
            style: AppTextStyles.body2.copyWith(
              color:
                  completedChallenges > 0 ? AppColors.main : AppColors.grey3,
              fontWeight: completedChallenges > 0 ? FontWeight.w600 : null,
            ),
          ),
          const Spacer(),
          Text(
            isAchieved
                ? '현재: 달성 완료!'
                : '현재: Day $completedDays/$targetDays',
            style: AppTextStyles.body2.copyWith(
              color: isAchieved ? AppColors.main : AppColors.grey3,
            ),
          ),
        ],
      ),
    );
  }

  bool _isDeadlinePassed(CrewDetail crew, DateTime now) {
    final deadlineStr = crew.deadlineTime ?? '23:59:59';
    final parts = deadlineStr.split(':');
    final deadline = DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
      parts.length > 2 ? int.parse(parts[2]) : 0,
    ).add(const Duration(minutes: 5));
    return now.isAfter(deadline);
  }

  String _getProgressMessage(String status, int completedDays) {
    if (status == 'SUCCESS') {
      return '\u{1F525} 작심삼일 달성! 대단해요!\u{1F525}';
    } else if (completedDays > 0) {
      return '작심삼일을 향해 달려가는 중! \u{1F3C3}';
    } else {
      return '작심삼일을 채워주세요!';
    }
  }

  Future<void> _navigateToVerification(
      BuildContext context, String? challengeId) async {
    final query = challengeId != null
        ? '/verification?crewId=$crewId&challengeId=$challengeId'
        : '/verification?crewId=$crewId';
    final result = await context.push<bool>(query);
    if (result == true && mounted) {
      setState(() {
        _justVerified = true;
      });
    }
  }

  Widget _buildChallengeProgressCard(
    BuildContext context,
    MyProgress progress,
    Set<DateTime> verifiedDates,
    CrewDetail crew,
  ) {
    final completedDays = progress.completedDays;
    final targetDays = progress.targetDays;
    final challengeId = progress.challengeId;
    final isCompleted = progress.status == 'SUCCESS';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isTodayVerified = verifiedDates.contains(today);
    final isDeadlinePassed = _isDeadlinePassed(crew, now);

    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(targetDays, (index) {
              final isDone = isCompleted || index < completedDays;
              return Padding(
                padding: EdgeInsets.only(
                  right: index < targetDays - 1 ? AppSizes.paddingLG : 0,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: isDone ? AppColors.main : AppColors.grey2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      'Day ${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: isDone ? AppColors.white : AppColors.grey3,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            _getProgressMessage(progress.status, completedDays),
            style: AppTextStyles.body2.copyWith(
              color: isCompleted ? AppColors.main : AppColors.grey3,
              fontWeight: isCompleted ? FontWeight.w600 : null,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          if (!isCompleted)
            if (isTodayVerified)
              Text(
                '오늘도 작심! 인증완료 \u{1F4AA}',
                style: AppTextStyles.body1.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              )
            else if (isDeadlinePassed)
              Text(
                '오늘 인증이 마감되었습니다',
                style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
              )
            else
              AppButton(
                text: '오늘의 작심 채우기',
                onPressed: () =>
                    _navigateToVerification(context, challengeId),
              ),
          const SizedBox(height: AppSizes.paddingXS),
        ],
      ),
    );
  }

  Widget _buildEmptyChallengeCard(
    BuildContext context,
    Set<DateTime> verifiedDates,
    CrewDetail crew,
    int completedChallenges,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isTodayVerified = verifiedDates.contains(today);
    final isDeadlinePassed = _isDeadlinePassed(crew, now);
    final hasCompletedBefore = completedChallenges > 0;

    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingSM),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              return Padding(
                padding: EdgeInsets.only(
                  right: index < 2 ? AppSizes.paddingLG : 0,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: hasCompletedBefore && isTodayVerified
                            ? AppColors.main
                            : AppColors.grey2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      'Day ${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: hasCompletedBefore && isTodayVerified
                            ? AppColors.white
                            : AppColors.grey3,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            hasCompletedBefore && isTodayVerified
                ? '\u{1F525} 작심삼일 달성! 대단해요!\u{1F525}'
                : '작심삼일을 채워주세요!',
            style: AppTextStyles.body2.copyWith(
              color: hasCompletedBefore && isTodayVerified
                  ? AppColors.main
                  : AppColors.grey3,
              fontWeight:
                  hasCompletedBefore && isTodayVerified ? FontWeight.w600 : null,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          if (hasCompletedBefore && isTodayVerified)
            const SizedBox.shrink()
          else if (isTodayVerified)
            Text(
              '오늘도 작심! 인증완료 \u{1F4AA}',
              style: AppTextStyles.body1.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            )
          else if (isDeadlinePassed)
            Text(
              '오늘 인증이 마감되었습니다',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
            )
          else
            AppButton(
              text: '오늘의 작심 채우기',
              onPressed: () => _navigateToVerification(context, null),
            ),
          const SizedBox(height: AppSizes.paddingXS),
        ],
      ),
    );
  }
}
