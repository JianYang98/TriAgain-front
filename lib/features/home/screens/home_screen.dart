import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/network/api_exception.dart';
import 'package:triagain/features/home/widgets/crew_card.dart';
import 'package:triagain/models/crew.dart';
import 'package:triagain/providers/crew_provider.dart';
import 'package:triagain/services/crew_service.dart';
import 'package:triagain/widgets/app_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crewsAsync = ref.watch(crewListProvider); // 구독 

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Image.asset('images/logo.png', height: 48),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TriAgain',
                  style: AppTextStyles.heading1.copyWith(color: AppColors.white),
                ),
                Text(
                  'Start Small. Try Again',
                  style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.white),
            onPressed: () => context.push('/crew/search'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline, color: AppColors.white),
            onPressed: () => context.push('/mypage'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.paddingMD),
              Expanded(
                child: crewsAsync.when(
                  data: (crews) {
                    if (crews.isEmpty) {
                      return Center(
                        child: Text(
                          '참여 중인 크루가 없어요.\n크루를 만들거나 초대코드로 참여해보세요!',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body1
                              .copyWith(color: AppColors.grey3),
                        ),
                      );
                    }
                    final activeCrews = crews
                        .where((c) => c.status != CrewStatus.completed)
                        .toList();
                    final completedCrews = crews
                        .where((c) => c.status == CrewStatus.completed)
                        .toList();
                    return RefreshIndicator(
                      color: AppColors.main,
                      onRefresh: () => ref.refresh(crewListProvider.future),
                      child: CustomScrollView(
                        slivers: [
                          SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppSizes.paddingMD),
                                child: CrewCard(
                                  crew: activeCrews[index],
                                  onTap: () => context
                                      .push('/crew/${activeCrews[index].id}'),
                                ),
                              ),
                              childCount: activeCrews.length,
                            ),
                          ),
                          if (completedCrews.isNotEmpty)
                            SliverToBoxAdapter(
                                child: _buildCompletedHeader()),
                          if (completedCrews.isNotEmpty)
                            SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) => Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSizes.paddingMD),
                                  child: CrewCard(
                                    crew: completedCrews[index],
                                    onTap: () => context.push(
                                        '/crew/${completedCrews[index].id}'),
                                  ),
                                ),
                                childCount: completedCrews.length,
                              ),
                            ),
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
                          '크루 목록을 불러올 수 없습니다',
                          style: AppTextStyles.body1
                              .copyWith(color: AppColors.grey3),
                        ),
                        const SizedBox(height: AppSizes.paddingSM),
                        TextButton(
                          onPressed: () =>
                              ref.invalidate(crewListProvider),
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
              const SizedBox(height: AppSizes.paddingMD),
              AppButton(
                text: '+ 크루 만들기',
                onPressed: () => context.push('/crew/create'),
              ),
              const SizedBox(height: AppSizes.paddingSM),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => context.push('/crew/search'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.grey1),
                          backgroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.buttonRadius),
                          ),
                        ),
                        child: Text(
                          '크루 찾기 🔍',
                          style: AppTextStyles.button
                              .copyWith(color: AppColors.grey4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSizes.paddingSM),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: () => _showInviteCodeDialog(context, ref),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.grey1),
                          backgroundColor: AppColors.background,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSizes.buttonRadius),
                          ),
                        ),
                        child: Text(
                          '초대코드 🔑',
                          style: AppTextStyles.button
                              .copyWith(color: AppColors.grey4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.paddingMD),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompletedHeader() {
    return Padding(
      padding: const EdgeInsets.only(
        top: AppSizes.paddingSM,
        bottom: AppSizes.paddingMD,
      ),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.grey1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingSM),
            child: Text(
              '종료된 크루',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
            ),
          ),
          const Expanded(child: Divider(color: AppColors.grey1)),
        ],
      ),
    );
  }

  void _showInviteCodeDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppColors.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          ),
          title: Text(
            '초대코드 입력',
            style: AppTextStyles.heading3.copyWith(color: AppColors.white),
          ),
          content: TextField(
            controller: controller,
            maxLength: 6,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
            ],
            style: AppTextStyles.body1.copyWith(color: AppColors.white),
            decoration: InputDecoration(
              hintText: '초대코드를 입력하세요',
              hintStyle: AppTextStyles.body2.copyWith(color: AppColors.grey3),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                borderSide: BorderSide(color: AppColors.grey1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                borderSide: BorderSide(color: AppColors.grey1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                borderSide: BorderSide(color: AppColors.main),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                '취소',
                style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
              ),
            ),
            TextButton(
              onPressed: () async {
                final code = controller.text.trim();
                if (code.isEmpty) return;
                if (code.length != 6) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(
                        content: Text('초대코드 6자리를 입력해주세요')),
                  );
                  return;
                }
                try {
                  final crewService = ref.read(crewServiceProvider);
                  final crew = await crewService.getCrewByInviteCode(code);
                  if (!dialogContext.mounted) return;
                  Navigator.of(dialogContext).pop();
                  if (context.mounted) {
                    context.push(
                        '/crew/confirm?crewId=${crew.id}&inviteCode=$code');
                  }
                } on ApiException catch (e) {
                  if (!dialogContext.mounted) return;
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(e.message)),
                  );
                }
              },
              child: Text(
                '확인',
                style: AppTextStyles.body2.copyWith(color: AppColors.main),
              ),
            ),
          ],
        );
      },
    );
  }
}
