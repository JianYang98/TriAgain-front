import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/models/mock_data.dart';
import 'package:triagain/widgets/app_button.dart';
import 'package:triagain/widgets/app_card.dart';

class MyVerificationTab extends StatelessWidget {
  final String crewId;

  const MyVerificationTab({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context) {
    final crew = MockData.crews.firstWhere((c) => c.id == crewId);
    final calendarData = MockData.getVerificationCalendarData(crewId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      child: Column(
        children: [
          _buildChallengeProgressCard(context, crew),
          const SizedBox(height: AppSizes.paddingMD),
          _buildCalendarCard(calendarData),
        ],
      ),
    );
  }

  Widget _buildChallengeProgressCard(BuildContext context, Crew crew) {
    return AppCard(
      child: Column(
        children: [
          const SizedBox(height: AppSizes.paddingSM),
          // Day dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (index) {
              final isCompleted = index < crew.currentDay;
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
                        color: isCompleted ? AppColors.main : AppColors.grey2,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: AppSizes.paddingXS),
                    Text(
                      'Day ${index + 1}',
                      style: AppTextStyles.caption.copyWith(
                        color: isCompleted ? AppColors.white : AppColors.grey3,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            '${crew.round}번째 도전',
            style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          AppButton(
            text: '📷 오늘 인증하기',
            onPressed: () => context.push('/verification?crewId=$crewId'),
          ),
          const SizedBox(height: AppSizes.paddingXS),
        ],
      ),
    );
  }

  Widget _buildCalendarCard(Map<DateTime, bool> calendarData) {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // weekday: 1=Mon, 7=Sun → offset for Mon-start grid
    final startOffset = firstDayOfMonth.weekday - 1;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$month월 인증 현황',
            style: AppTextStyles.heading3.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: AppSizes.paddingMD),
          // Weekday headers
          Row(
            children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.grey3,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: AppSizes.paddingSM),
          // Calendar grid
          ..._buildCalendarRows(
            year,
            month,
            daysInMonth,
            startOffset,
            calendarData,
          ),
          const SizedBox(height: AppSizes.paddingMD),
          // Legend
          _buildLegend(),
        ],
      ),
    );
  }

  List<Widget> _buildCalendarRows(
    int year,
    int month,
    int daysInMonth,
    int startOffset,
    Map<DateTime, bool> calendarData,
  ) {
    final rows = <Widget>[];
    int day = 1;

    while (day <= daysInMonth) {
      final cells = <Widget>[];
      for (int col = 0; col < 7; col++) {
        if ((rows.isEmpty && col < startOffset) || day > daysInMonth) {
          cells.add(const Expanded(child: SizedBox(height: 40)));
        } else {
          final date = DateTime(year, month, day);
          final isCompletedRound = calendarData[date];

          Color? circleColor;
          if (isCompletedRound == true) {
            circleColor = AppColors.success;
          } else if (isCompletedRound == false) {
            circleColor = AppColors.main;
          }

          cells.add(Expanded(
            child: SizedBox(
              height: 40,
              child: Center(
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: circleColor != null
                      ? BoxDecoration(
                          color: circleColor,
                          shape: BoxShape.circle,
                        )
                      : null,
                  alignment: Alignment.center,
                  child: Text(
                    '$day',
                    style: AppTextStyles.body2.copyWith(
                      color: circleColor != null
                          ? AppColors.white
                          : AppColors.grey3,
                    ),
                  ),
                ),
              ),
            ),
          ));
          day++;
        }
      }
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: AppSizes.paddingXS),
        child: Row(children: cells),
      ));
    }

    return rows;
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem(AppColors.success, '작심삼일 달성'),
        const SizedBox(width: AppSizes.paddingMD),
        _buildLegendItem(AppColors.main, '인증 완료'),
      ],
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppSizes.paddingXS),
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
        ),
      ],
    );
  }
}
