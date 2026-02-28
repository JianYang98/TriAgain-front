class FeedVerification {
  final String id;
  final String userId;
  final String nickname;
  final String? profileImageUrl;
  final String? imageUrl;
  final String? textContent;
  final DateTime targetDate;
  final DateTime createdAt;

  const FeedVerification({
    required this.id,
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
    this.imageUrl,
    this.textContent,
    required this.targetDate,
    required this.createdAt,
  });

  factory FeedVerification.fromJson(Map<String, dynamic> json) {
    return FeedVerification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      imageUrl: json['imageUrl'] as String?,
      textContent: json['textContent'] as String?,
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class MyProgress {
  final String challengeId;
  final String status;
  final int completedDays;
  final int targetDays;

  const MyProgress({
    required this.challengeId,
    required this.status,
    required this.completedDays,
    required this.targetDays,
  });

  factory MyProgress.fromJson(Map<String, dynamic> json) {
    return MyProgress(
      challengeId: json['challengeId'] as String,
      status: json['status'] as String,
      completedDays: json['completedDays'] as int,
      targetDays: json['targetDays'] as int,
    );
  }
}

class FeedResult {
  final List<FeedVerification> verifications;
  final MyProgress myProgress;
  final bool hasNext;

  const FeedResult({
    required this.verifications,
    required this.myProgress,
    required this.hasNext,
  });

  factory FeedResult.fromJson(Map<String, dynamic> json) {
    return FeedResult(
      verifications: (json['verifications'] as List)
          .map((v) => FeedVerification.fromJson(v as Map<String, dynamic>))
          .toList(),
      myProgress:
          MyProgress.fromJson(json['myProgress'] as Map<String, dynamic>),
      hasNext: json['hasNext'] as bool,
    );
  }
}

class VerificationResult {
  final String verificationId;
  final String challengeId;
  final String userId;
  final String crewId;
  final String? imageUrl;
  final String? textContent;
  final String status;
  final String reviewStatus;
  final int reportCount;
  final DateTime targetDate;
  final DateTime createdAt;

  const VerificationResult({
    required this.verificationId,
    required this.challengeId,
    required this.userId,
    required this.crewId,
    this.imageUrl,
    this.textContent,
    required this.status,
    required this.reviewStatus,
    required this.reportCount,
    required this.targetDate,
    required this.createdAt,
  });

  factory VerificationResult.fromJson(Map<String, dynamic> json) {
    return VerificationResult(
      verificationId: json['verificationId'] as String,
      challengeId: json['challengeId'] as String,
      userId: json['userId'] as String,
      crewId: json['crewId'] as String,
      imageUrl: json['imageUrl'] as String?,
      textContent: json['textContent'] as String?,
      status: json['status'] as String,
      reviewStatus: json['reviewStatus'] as String,
      reportCount: json['reportCount'] as int,
      targetDate: DateTime.parse(json['targetDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
