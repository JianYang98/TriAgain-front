import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/features/crew/widgets/verification_calendar.dart';
import 'package:triagain/models/verification.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/providers/verification_provider.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/app_card.dart';

class MyVerificationTab extends ConsumerWidget {
  final String crewId;

  const MyVerificationTab({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider(crewId));
    final datesAsync = ref.watch(myVerificationDatesProvider(crewId));
    final crewAsync = ref.watch(crewDetailProvider(crewId));

    final crew = crewAsync.valueOrNull;
    if (crew == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.main),
      );
    }

    return feedAsync.when(
      data: (feed) {
        final progress = feed.myProgress;
        final verifiedDates = datesAsync.valueOrNull ?? {};
        final userId = ref.watch(authUserIdProvider);

        // 내 가입일 찾기
        DateTime joinedAt = crew.startDate;
        if (userId != null) {
          for (final m in crew.members) {
            if (m.userId == userId) {
              joinedAt = DateTime(
                m.joinedAt.year,
                m.joinedAt.month,
                m.joinedAt.day,
              );
              break;
            }
          }
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
              _buildStreakSummary(verifiedDates, joinedAt, crew.endDate,
                  progress),
              const SizedBox(height: AppSizes.paddingMD),
              _buildChallengeProgressCard(context, progress),
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
              onPressed: () {
                ref.invalidate(feedProvider(crewId));
                ref.invalidate(myVerificationDatesProvider(crewId));
              },
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

  Widget _buildStreakSummary(
    Set<DateTime> verifiedDates,
    DateTime joinedAt,
    DateTime crewEnd,
    MyProgress progress,
  ) {
    final streakCount =
        _countCompletedStreaks(verifiedDates, joinedAt, crewEnd);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingXS),
      child: Row(
        children: [
          Text(
            '작심삼일 $streakCount회 달성',
            style: AppTextStyles.body2.copyWith(
              color: streakCount > 0 ? AppColors.main : AppColors.grey3,
              fontWeight: streakCount > 0 ? FontWeight.w600 : null,
            ),
          ),
          const Spacer(),
          Text(
            '현재: Day ${progress.completedDays}/${progress.targetDays}',
            style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
          ),
        ],
      ),
    );
  }

  int _countCompletedStreaks(
      Set<DateTime> verifiedDates, DateTime joinedAt, DateTime crewEnd) {
    int count = 0;
    final joined = DateTime(joinedAt.year, joinedAt.month, joinedAt.day);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final end = DateTime(crewEnd.year, crewEnd.month, crewEnd.day);
    final limit = today.isBefore(end) ? today : end;

    var blockStart = joined;
    while (!blockStart.isAfter(limit)) {
      final day1 = blockStart;
      final day2 = blockStart.add(const Duration(days: 1));
      final day3 = blockStart.add(const Duration(days: 2));

      if (verifiedDates.contains(day1) &&
          verifiedDates.contains(day2) &&
          verifiedDates.contains(day3)) {
        count++;
      }
      blockStart = blockStart.add(const Duration(days: 3));
    }
    return count;
  }

  Widget _buildChallengeProgressCard(
      BuildContext context, MyProgress progress) {
    final completedDays = progress.completedDays;
    final targetDays = progress.targetDays;
    final challengeId = progress.challengeId;
    final isCompleted = completedDays >= targetDays;

    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingSM),
          // Day dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(targetDays, (index) {
              final isDone = index < completedDays;
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
            isCompleted
                ? '작심삼일 달성!'
                : '$completedDays/$targetDays일 완료',
            style: AppTextStyles.body2.copyWith(
              color: isCompleted ? AppColors.success : AppColors.grey3,
              fontWeight: isCompleted ? FontWeight.w600 : null,
            ),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          if (!isCompleted)
            AppButton(
              text: '오늘 인증하기',
              onPressed: () => context.push(
                  '/verification?crewId=$crewId&challengeId=$challengeId'),
            ),
          const SizedBox(height: AppSizes.paddingXS),
        ],
      ),
    );
  }
}
