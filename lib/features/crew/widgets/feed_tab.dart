import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/constants/app_colors.dart';
import 'package:triagain/core/constants/app_sizes.dart';
import 'package:triagain/core/constants/app_text_styles.dart';
import 'package:triagain/models/verification.dart';
import 'package:triagain/providers/verification_provider.dart';
import 'package:triagain/services/verification_service.dart';

class FeedTab extends ConsumerStatefulWidget {
  final String crewId;

  const FeedTab({
    super.key,
    required this.crewId,
  });

  @override
  ConsumerState<FeedTab> createState() => _FeedTabState();
}

class _FeedTabState extends ConsumerState<FeedTab> {
  final ScrollController _scrollController = ScrollController();
  List<FeedVerification> _verifications = [];
  bool _hasNext = false;
  int _currentPage = 0;
  bool _isLoadingMore = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasNext) return;
    setState(() => _isLoadingMore = true);

    try {
      final service = ref.read(verificationServiceProvider);
      final result =
          await service.getFeed(widget.crewId, page: _currentPage + 1);
      if (mounted) {
        setState(() {
          _verifications.addAll(result.verifications);
          _hasNext = result.hasNext;
          _currentPage++;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  void _initFromFeed(FeedResult feed) {
    if (!_isInitialized) {
      _verifications = List.of(feed.verifications);
      _hasNext = feed.hasNext;
      _currentPage = 0;
      _isInitialized = true;
    }
  }

  void _resetState() {
    _verifications = [];
    _hasNext = false;
    _currentPage = 0;
    _isInitialized = false;
  }

  @override
  Widget build(BuildContext context) {
    final feedAsync = ref.watch(feedProvider(widget.crewId));

    ref.listen(feedProvider(widget.crewId), (prev, next) {
      if (prev?.hasValue == true && next.hasValue) {
        _resetState();
      }
    });

    return feedAsync.when(
      data: (feed) {
        _initFromFeed(feed);

        if (_verifications.isEmpty) {
          return Center(
            child: Text(
              '아직 인증이 없어요',
              style: AppTextStyles.body2.copyWith(color: AppColors.grey3),
            ),
          );
        }

        final grouped = _groupByDate(_verifications);
        final items = _buildFlatItems(grouped);

        return ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(AppSizes.paddingMD),
          itemCount: items.length + (_isLoadingMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == items.length) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSizes.paddingMD),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.main),
                ),
              );
            }
            return items[index];
          },
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
              onPressed: () {
                _resetState();
                ref.invalidate(feedProvider(widget.crewId));
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

  List<Widget> _buildFlatItems(
      List<MapEntry<DateTime, List<FeedVerification>>> grouped) {
    final items = <Widget>[];
    for (int i = 0; i < grouped.length; i++) {
      if (i > 0) items.add(const SizedBox(height: AppSizes.paddingMD));
      items.add(Text(
        _formatDateHeader(grouped[i].key),
        style: AppTextStyles.heading3.copyWith(color: AppColors.white),
      ));
      items.add(const SizedBox(height: AppSizes.paddingSM));
      for (int j = 0; j < grouped[i].value.length; j++) {
        if (j > 0) items.add(const SizedBox(height: AppSizes.paddingMD));
        items.add(_FeedCard(verification: grouped[i].value[j]));
      }
    }
    return items;
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
            child: CachedNetworkImage(
              imageUrl: verification.imageUrl!,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                width: double.infinity,
                height: 200,
                color: AppColors.card,
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.main,
                    strokeWidth: 2,
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
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
