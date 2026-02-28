import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/verification.dart';
import 'package:triagain/providers/verification_provider.dart';

class FeedTab extends ConsumerWidget {
  final String crewId;

  const FeedTab({
    super.key,
    required this.crewId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedAsync = ref.watch(feedProvider(crewId));

    return feedAsync.when(
      data: (feed) {
        final verifications = feed.verifications;

        if (verifications.isEmpty) {
          return Center(
            child: Text(
              '아직 인증이 없어요',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
            ),
          );
        }

        final grouped = _groupByDate(verifications);

        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < grouped.length; i++) ...[
                if (i > 0) const SizedBox(height: AppSizes.paddingMD),
                Text(
                  _formatDateHeader(grouped[i].key),
                  style:
                      AppTextStyles.heading3.copyWith(color: AppColors.white),
                ),
                const SizedBox(height: AppSizes.paddingSM),
                for (int j = 0; j < grouped[i].value.length; j++) ...[
                  if (j > 0) const SizedBox(height: AppSizes.paddingMD),
                  _FeedCard(verification: grouped[i].value[j]),
                ],
              ],
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
              '피드를 불러올 수 없습니다',
              style: AppTextStyles.body1.copyWith(color: AppColors.grey3),
            ),
            const SizedBox(height: AppSizes.paddingSM),
            TextButton(
              onPressed: () => ref.invalidate(feedProvider(crewId)),
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

  List<MapEntry<DateTime, List<FeedVerification>>> _groupByDate(
      List<FeedVerification> feed) {
    final map = <DateTime, List<FeedVerification>>{};
    for (final v in feed) {
      final dateKey =
          DateTime(v.createdAt.year, v.createdAt.month, v.createdAt.day);
      map.putIfAbsent(dateKey, () => []).add(v);
    }
    final entries = map.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));
    return entries;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    if (date == today) {
      return '오늘 (${date.month}/${date.day})';
    } else if (date == yesterday) {
      return '어제 (${date.month}/${date.day})';
    }
    return '${date.month}/${date.day}';
  }
}

class _FeedCard extends StatelessWidget {
  final FeedVerification verification;

  const _FeedCard({required this.verification});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name + relative time
        Row(
          children: [
            Text(
              verification.nickname,
              style: AppTextStyles.body2.copyWith(color: AppColors.white),
            ),
            const Spacer(),
            Text(
              _formatRelativeTime(verification.createdAt),
              style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
            ),
          ],
        ),
        // Image
        if (verification.imageUrl != null) ...[
          const SizedBox(height: AppSizes.paddingSM),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSizes.cardRadius),
            child: Image.network(
              verification.imageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                ),
                child: const Icon(
                  Icons.image_not_supported_outlined,
                  color: AppColors.grey3,
                  size: 40,
                ),
              ),
            ),
          ),
        ],
        // Text
        if (verification.textContent != null) ...[
          const SizedBox(height: AppSizes.paddingSM),
          Text(
            verification.textContent!,
            style: AppTextStyles.body2.copyWith(color: AppColors.grey4),
          ),
        ],
        // Like
        const SizedBox(height: AppSizes.paddingSM),
        Row(
          children: [
            const Icon(
              Icons.thumb_up_outlined,
              color: AppColors.grey3,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '0',
              style: AppTextStyles.caption.copyWith(color: AppColors.grey3),
            ),
          ],
        ),
      ],
    );
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 1) {
      return '방금 전';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}분 전';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}시간 전';
    } else {
      return '${diff.inDays}일 전';
    }
  }
}
