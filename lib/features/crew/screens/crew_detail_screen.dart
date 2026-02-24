import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/features/crew/widgets/feed_tab.dart';
import 'package:triagain/features/crew/widgets/member_status_tab.dart';
import 'package:triagain/features/crew/widgets/crew_info_bottom_sheet.dart';
import 'package:triagain/features/crew/widgets/my_verification_tab.dart';
import 'package:triagain/models/mock_data.dart';

class CrewDetailScreen extends StatelessWidget {
  final String crewId;

  const CrewDetailScreen({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context) {
    final crew = MockData.crews.firstWhere((c) => c.id == crewId);

    String motivationText;
    if (crew.currentDay == 1) {
      motivationText = '새로운 도전 시작!';
    } else if (crew.currentDay == 2) {
      motivationText = '오늘만 하면 달성!';
    } else {
      motivationText = '마지막 날! 화이팅!';
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
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
                      ),
                    ),
                    const SizedBox(width: AppSizes.paddingSM),
                    Text(
                      crew.name,
                      style: AppTextStyles.heading3.copyWith(
                        color: AppColors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => _showCrewInfoSheet(context, crew),
                      icon: const Icon(
                        Icons.info_outline,
                        color: AppColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              // Banner
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.paddingMD,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSizes.paddingMD),
                  decoration: BoxDecoration(
                    color: AppColors.main,
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '작심삼일 ${crew.round}번째 🔥',
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXS),
                      Text(
                        motivationText,
                        style: AppTextStyles.body2.copyWith(
                          color: AppColors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSizes.paddingMD),

              // TabBar
              TabBar(
                indicatorColor: AppColors.main,
                labelColor: AppColors.white,
                unselectedLabelColor: AppColors.grey3,
                dividerColor: AppColors.grey1,
                labelStyle: AppTextStyles.body1.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: AppTextStyles.body1,
                tabs: const [
                  Tab(text: '나의 인증'),
                  Tab(text: '참가자 현황'),
                  Tab(text: '인증 피드'),
                ],
              ),

              // TabBarView
              Expanded(
                child: TabBarView(
                  children: [
                    MyVerificationTab(crewId: crewId),
                    MemberStatusTab(crewId: crewId),
                    FeedTab(crewId: crewId),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCrewInfoSheet(BuildContext context, Crew crew) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CrewInfoBottomSheet(crew: crew),
    );
  }
}
