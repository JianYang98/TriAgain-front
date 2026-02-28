import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/features/crew/widgets/feed_tab.dart';
import 'package:triagain/features/crew/widgets/member_status_tab.dart';
import 'package:triagain/features/crew/widgets/crew_info_bottom_sheet.dart';
import 'package:triagain/features/crew/widgets/my_verification_tab.dart';
import 'package:triagain/providers/crew_provider.dart';

class CrewDetailScreen extends ConsumerWidget {
  final String crewId;

  const CrewDetailScreen({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crewAsync = ref.watch(crewDetailProvider(crewId));

    return crewAsync.when(
      data: (crew) => _buildScreen(context, ref, crew),
      loading: () => Scaffold(
        backgroundColor: AppColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.main),
        ),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
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
                  ],
                ),
              ),
              Expanded(
                child: Center(
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context, WidgetRef ref, CrewDetail crew) {
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
                        crew.status.label,
                        style: AppTextStyles.heading3.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppSizes.paddingXS),
                      Text(
                        crew.goal,
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

  void _showCrewInfoSheet(BuildContext context, CrewDetail crew) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => CrewInfoBottomSheet(crew: crew),
    );
  }
}
