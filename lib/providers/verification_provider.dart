import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/models/verification.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/services/verification_service.dart';

final feedProvider =
    FutureProvider.family<FeedResult, String>((ref, crewId) async {
  final verificationService = ref.watch(verificationServiceProvider);
  return verificationService.getFeed(crewId);
});

final myVerificationDatesProvider =
    FutureProvider.family<Set<DateTime>, String>((ref, crewId) async {
  final userId = ref.watch(authUserIdProvider);
  if (userId == null) return {};

  final service = ref.watch(verificationServiceProvider);
  final Set<DateTime> dates = {};
  int page = 0;
  bool hasNext = true;

  while (hasNext && page < 5) {
    final feed = await service.getFeed(crewId, page: page, size: 50);
    for (final v in feed.verifications) {
      if (v.userId == userId) {
        dates.add(DateTime(
          v.targetDate.year,
          v.targetDate.month,
          v.targetDate.day,
        ));
      }
    }
    hasNext = feed.hasNext;
    page++;
  }
  return dates;
});
