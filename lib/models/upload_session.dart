class UploadSession {
  final int uploadSessionId;
  final String presignedUrl;
  final String imageUrl;
  final DateTime expiresAt;
  final int maxFileSize;
  final List<String> allowedTypes;

  const UploadSession({
    required this.uploadSessionId,
    required this.presignedUrl,
    required this.imageUrl,
    required this.expiresAt,
    required this.maxFileSize,
    required this.allowedTypes,
  });

  factory UploadSession.fromJson(Map<String, dynamic> json) {
    return UploadSession(
      uploadSessionId: json['uploadSessionId'] as int,
      presignedUrl: json['presignedUrl'] as String,
      imageUrl: json['imageUrl'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      maxFileSize: json['maxFileSize'] as int,
      allowedTypes: (json['allowedTypes'] as List)
          .map((e) => e as String)
          .toList(),
    );
  }

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt);
}

class UploadSessionStatus {
  final int uploadSessionId;
  final String status;

  const UploadSessionStatus({
    required this.uploadSessionId,
    required this.status,
  });

  factory UploadSessionStatus.fromJson(Map<String, dynamic> json) {
    return UploadSessionStatus(
      uploadSessionId: json['uploadSessionId'] as int,
      status: json['status'] as String,
    );
  }
}

enum UploadSessionEvent {
  completed,
  expired,
  error,
}
