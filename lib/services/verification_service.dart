import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:triagain/core/network/api_client.dart';
import 'package:triagain/models/verification.dart';

final verificationServiceProvider = Provider<VerificationService>((ref) {
  return VerificationService(ref.watch(apiClientProvider));
});

class VerificationService {
  final ApiClient _apiClient;

  VerificationService(this._apiClient);

  Future<FeedResult> getFeed(String crewId,
      {int page = 0, int size = 20}) async {
    final response = await _apiClient.get<FeedResult>(
      '/crews/$crewId/feed',
      queryParameters: {'page': page, 'size': size},
      fromData: (json) => FeedResult.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }

  Future<VerificationResult> createVerification({
    required String challengeId,
    int? uploadSessionId,
    String? textContent,
    required String idempotencyKey,
  }) async {
    final response = await _apiClient.post<VerificationResult>(
      '/verifications',
      data: {
        'challengeId': challengeId,
        if (uploadSessionId != null) 'uploadSessionId': uploadSessionId,
        if (textContent != null) 'textContent': textContent,
      },
      extraHeaders: {'Idempotency-Key': idempotencyKey},
      fromData: (json) =>
          VerificationResult.fromJson(json as Map<String, dynamic>),
    );
    return response.data!;
  }
}
