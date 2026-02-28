import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/models/verification.dart';
import 'package:triagain/services/verification_service.dart';

final feedProvider =
    FutureProvider.family<FeedResult, String>((ref, crewId) async {
  final verificationService = ref.watch(verificationServiceProvider);
  return verificationService.getFeed(crewId);
});
