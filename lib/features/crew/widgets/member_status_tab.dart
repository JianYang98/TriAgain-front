import 'package:flutter/material.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/mock_data.dart';
import 'package:triagain/widgets/app_card.dart';

class MemberStatusTab extends StatelessWidget {
  final String crewId;

  const MemberStatusTab({
    super.key,
    required this.crewId,
  });

  static const _maxBarHeight = 200.0;
  static const _barWidth = 56.0;

  @override
  Widget build(BuildContext context) {
    final members = MockData.getMemberStatsForCrew(crewId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSizes.paddingMD),
      child: AppCard(
        child: Column(
          children: [
            const SizedBox(height: AppSizes.paddingSM),
            // Bar chart area
            SizedBox(
              height: _maxBarHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: members.map((m) {
                  final rate = (m['rate'] as int).toDouble();
                  final barHeight = _maxBarHeight * rate / 100;
                  return Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: _buildBar(barHeight, rate.toInt()),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: AppSizes.paddingSM),
            // Rank badges + names
            Row(
              children: members.map((m) {
                return Expanded(
                  child: Column(
                    children: [
                      _buildRankBadge(m['rank'] as int),
                      const SizedBox(height: AppSizes.paddingXS),
                      Text(
                        m['name'] as String,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: AppSizes.paddingSM),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(double height, int rate) {
    return Container(
      height: height,
      width: _barWidth,
      decoration: const BoxDecoration(
        color: AppColors.main,
        borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
      ),
      alignment: Alignment.center,
      child: Text(
        '$rate%',
        style: AppTextStyles.body2.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: AppColors.main,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        '$rank',
        style: AppTextStyles.caption.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
