import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/features/crew/widgets/feed_tab.dart';
import 'package:triagain/features/crew/widgets/member_status_tab.dart';
import 'package:triagain/features/crew/widgets/crew_info_bottom_sheet.dart';
import 'package:triagain/features/crew/widgets/crew_manage_bottom_sheet.dart';
import 'package:triagain/features/crew/widgets/my_verification_tab.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/providers/verification_provider.dart';
import 'package:triagain/services/crew_service.dart';

class CrewDetailScreen extends ConsumerStatefulWidget {
  final String crewId;

  const CrewDetailScreen({
    super.key,
    required this.crewId,
  });

  @override
  ConsumerState<CrewDetailScreen> createState() => _CrewDetailScreenState();
}

class _CrewDetailScreenState extends ConsumerState<CrewDetailScreen> {
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(crewDetailProvider(widget.crewId));
      ref.invalidate(myVerificationsProvider(widget.crewId));
      ref.invalidate(feedProvider(widget.crewId));
    });
  }

  @override
  Widget build(BuildContext context) {
    final crewAsync = ref.watch(crewDetailProvider(widget.crewId));

    return crewAsync.when(
      data: (crew) => _buildScreen(context, crew),
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
                            ref.invalidate(crewDetailProvider(widget.crewId)),
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

  Widget _buildScreen(BuildContext context, CrewDetail crew) {
    final currentUserId = ref.read(authUserIdProvider);
    final myMember = crew.members
        .where((m) => m.userId == currentUserId)
        .firstOrNull;
    final isLeader = myMember?.isLeader ?? false;
    final isRecruiting = crew.status == CrewStatus.recruiting;
    final isMember = myMember != null && !isLeader;

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
                    if (isLeader && isRecruiting)
                      IconButton(
                        onPressed: () =>
                            _showManageSheet(context, crew),
                        icon: const Icon(
                          Icons.more_vert,
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
                      if (crew.verificationContent != null) ...[
                        const SizedBox(height: AppSizes.paddingXS),
                        Text(
                          '인증 내용  ${crew.verificationContent!}',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
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
                    MyVerificationTab(crewId: widget.crewId),
                    MemberStatusTab(crewId: widget.crewId),
                    FeedTab(crewId: widget.crewId),
                  ],
                ),
              ),

              // 크루 탈퇴 텍스트 (MEMBER + RECRUITING)
              if (isMember && isRecruiting)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSizes.paddingMD,
                    top: AppSizes.paddingXS,
                  ),
                  child: GestureDetector(
                    onTap: () => _showLeaveDialog(context, crew.name),
                    child: Text(
                      '크루 탈퇴',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.grey3,
                        fontSize: 14,
                      ),
                    ),
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

  void _showManageSheet(BuildContext context, CrewDetail crew) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => CrewManageBottomSheet(
        currentMembers: crew.currentMembers,
        onEdit: () {
          Navigator.of(context).pop();
          context.push('/crew/${widget.crewId}/edit');
        },
        onDelete: () {
          Navigator.of(context).pop();
          _showDeleteDialog(context, crew.name);
        },
      ),
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, String crewName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          '크루를 삭제하시겠습니까?',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        content: Text(
          '삭제된 크루는 복구할 수 없습니다.',
          style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '삭제',
              style: AppTextStyles.body1.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final crewService = ref.read(crewServiceProvider);
      await crewService.deleteCrew(widget.crewId);

      ref.invalidate(crewListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('크루가 삭제되었습니다')),
      );
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showLeaveDialog(BuildContext context, String crewName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.card,
        title: Text(
          '크루에서 탈퇴하시겠습니까?',
          style: AppTextStyles.heading3.copyWith(color: AppColors.white),
        ),
        content: Text(
          '탈퇴 후 다시 초대코드로 가입할 수 있습니다.',
          style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '취소',
              style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              '탈퇴',
              style: AppTextStyles.body1.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final crewService = ref.read(crewServiceProvider);
      await crewService.leaveCrew(widget.crewId);

      ref.invalidate(crewListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('크루에서 탈퇴했습니다')),
      );
      context.go('/home');
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
