enum VerificationStatus {
  pending,
  completed,
}

class Verification {
  final String id;
  final String challengeId;
  final String userId;
  final String? imageUrl;
  final String? text;
  final DateTime createdAt;
  final VerificationStatus status;

  const Verification({
    required this.id,
    required this.challengeId,
    required this.userId,
    this.imageUrl,
    this.text,
    required this.createdAt,
    required this.status,
  });
}
