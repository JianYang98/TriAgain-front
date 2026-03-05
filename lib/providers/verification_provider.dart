import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/models/verification.dart';
import 'package:triagain/services/verification_service.dart';

final feedProvider =
    FutureProvider.family<FeedResult, String>((ref, crewId) async {
  final service = ref.watch(verificationServiceProvider);
  return service.getFeed(crewId);
});

final myVerificationsProvider =
    FutureProvider.family<MyVerificationsResult, String>((ref, crewId) async {
  final service = ref.watch(verificationServiceProvider);
  for (int attempt = 0; attempt < 3; attempt++) {
    try {
      return await service.getMyVerifications(crewId);
    } catch (e) {
      if (attempt == 2) rethrow;
      await Future.delayed(Duration(seconds: attempt + 1));
    }
  }
  throw StateError('unreachable');
});
