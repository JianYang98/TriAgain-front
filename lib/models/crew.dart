enum CrewStatus {
  recruiting,
  active,
  completed;

  factory CrewStatus.fromString(String value) {
    return switch (value) {
      'RECRUITING' => CrewStatus.recruiting,
      'ACTIVE' => CrewStatus.active,
      'COMPLETED' => CrewStatus.completed,
      _ => throw ArgumentError('Unknown CrewStatus: $value'),
    };
  }

  String get label => switch (this) {
    CrewStatus.recruiting => '모집중',
    CrewStatus.active => '진행중',
    CrewStatus.completed => '완료',
  };
}

enum VerificationType {
  text,
  photo;

  factory VerificationType.fromString(String value) {
    return switch (value) {
      'TEXT' => VerificationType.text,
      'PHOTO' => VerificationType.photo,
      _ => throw ArgumentError('Unknown VerificationType: $value'),
    };
  }

  String toJson() => switch (this) {
    VerificationType.text => 'TEXT',
    VerificationType.photo => 'PHOTO',
  };
}

enum CrewCategory {
  exercise,
  study,
  lifestyle,
  selfDev,
  etc;

  factory CrewCategory.fromString(String value) {
    return switch (value) {
      'EXERCISE' => CrewCategory.exercise,
      'STUDY' => CrewCategory.study,
      'LIFESTYLE' => CrewCategory.lifestyle,
      'SELF_DEV' => CrewCategory.selfDev,
      'ETC' => CrewCategory.etc,
      _ => throw ArgumentError('Unknown CrewCategory: $value'),
    };
  }

  String toJson() => switch (this) {
    CrewCategory.exercise => 'EXERCISE',
    CrewCategory.study => 'STUDY',
    CrewCategory.lifestyle => 'LIFESTYLE',
    CrewCategory.selfDev => 'SELF_DEV',
    CrewCategory.etc => 'ETC',
  };

  String get label => switch (this) {
    CrewCategory.exercise => '운동',
    CrewCategory.study => '공부',
    CrewCategory.lifestyle => '생활습관',
    CrewCategory.selfDev => '자기개발',
    CrewCategory.etc => '기타',
  };
}

enum CrewVisibility {
  public,
  private;

  factory CrewVisibility.fromString(String value) {
    return switch (value) {
      'PUBLIC' => CrewVisibility.public,
      'PRIVATE' => CrewVisibility.private,
      _ => throw ArgumentError('Unknown CrewVisibility: $value'),
    };
  }

  String toJson() => switch (this) {
    CrewVisibility.public => 'PUBLIC',
    CrewVisibility.private => 'PRIVATE',
  };
}

class CrewSummary {
  final String id;
  final String name;
  final String goal;
  final VerificationType verificationType;
  final int currentMembers;
  final int maxMembers;
  final CrewStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;
  final String? deadlineTime;
  final CrewCategory? category;
  final CrewVisibility? visibility;

  const CrewSummary({
    required this.id,
    required this.name,
    required this.goal,
    required this.verificationType,
    required this.currentMembers,
    required this.maxMembers,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.deadlineTime,
    this.category,
    this.visibility,
  });

  factory CrewSummary.fromJson(Map<String, dynamic> json) {
    return CrewSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      goal: json['goal'] as String,
      verificationType:
          VerificationType.fromString(json['verificationType'] as String),
      currentMembers: json['currentMembers'] as int,
      maxMembers: json['maxMembers'] as int,
      status: CrewStatus.fromString(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      deadlineTime: json['deadlineTime'] as String?,
      category: json['category'] != null
          ? CrewCategory.fromString(json['category'] as String)
          : null,
      visibility: json['visibility'] != null
          ? CrewVisibility.fromString(json['visibility'] as String)
          : null,
    );
  }
}

class ChallengeProgress {
  final String challengeStatus;
  final int completedDays;
  final int targetDays;

  const ChallengeProgress({
    required this.challengeStatus,
    required this.completedDays,
    required this.targetDays,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> json) {
    return ChallengeProgress(
      challengeStatus: json['challengeStatus'] as String,
      completedDays: json['completedDays'] as int,
      targetDays: json['targetDays'] as int,
    );
  }
}

class CrewMember {
  final String? userId;
  final String nickname;
  final String? profileImageUrl;
  final String role;
  final DateTime? joinedAt;
  final int successCount;
  final ChallengeProgress? challengeProgress;

  const CrewMember({
    this.userId,
    required this.nickname,
    this.profileImageUrl,
    required this.role,
    this.joinedAt,
    this.successCount = 0,
    this.challengeProgress,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      userId: json['userId'] as String?,
      nickname: json['nickname'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      role: json['role'] as String,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
      successCount: json['successCount'] as int? ?? 0,
      challengeProgress: json['challengeProgress'] != null
          ? ChallengeProgress.fromJson(
              json['challengeProgress'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isLeader => role == 'LEADER';
}

class CrewDetail {
  final String id;
  final String? creatorId;
  final String name;
  final String goal;
  final VerificationType verificationType;
  final int maxMembers;
  final int currentMembers;
  final CrewStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool allowLateJoin;
  final String? inviteCode;
  final DateTime? createdAt;
  final List<CrewMember> members;
  final String? deadlineTime;
  final bool? joinable;
  final String? joinBlockedReason;
  final String? verificationContent;
  final CrewCategory? category;
  final CrewVisibility? visibility;

  const CrewDetail({
    required this.id,
    this.creatorId,
    required this.name,
    required this.goal,
    required this.verificationType,
    required this.maxMembers,
    required this.currentMembers,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.allowLateJoin,
    this.inviteCode,
    this.createdAt,
    required this.members,
    this.deadlineTime,
    this.joinable,
    this.joinBlockedReason,
    this.verificationContent,
    this.category,
    this.visibility,
  });

  factory CrewDetail.fromJson(Map<String, dynamic> json) {
    return CrewDetail(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String?,
      name: json['name'] as String,
      goal: json['goal'] as String,
      verificationType:
          VerificationType.fromString(json['verificationType'] as String),
      maxMembers: json['maxMembers'] as int,
      currentMembers: json['currentMembers'] as int,
      status: CrewStatus.fromString(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      allowLateJoin: json['allowLateJoin'] as bool,
      inviteCode: json['inviteCode'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      members: (json['members'] as List)
          .map((m) => CrewMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      deadlineTime: json['deadlineTime'] as String?,
      joinable: json['joinable'] as bool?,
      joinBlockedReason: json['joinBlockedReason'] as String?,
      verificationContent: json['verificationContent'] as String?,
      category: json['category'] != null
          ? CrewCategory.fromString(json['category'] as String)
          : null,
      visibility: json['visibility'] != null
          ? CrewVisibility.fromString(json['visibility'] as String)
          : null,
    );
  }
}

class SearchCrewItem {
  final String id;
  final String name;
  final String goal;
  final String? verificationContent;
  final CrewCategory? category;
  final VerificationType verificationType;
  final bool allowLateJoin;
  final int currentMembers;
  final int maxMembers;
  final CrewStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  const SearchCrewItem({
    required this.id,
    required this.name,
    required this.goal,
    this.verificationContent,
    this.category,
    required this.verificationType,
    required this.allowLateJoin,
    required this.currentMembers,
    required this.maxMembers,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  factory SearchCrewItem.fromJson(Map<String, dynamic> json) {
    return SearchCrewItem(
      id: json['id'] as String,
      name: json['name'] as String,
      goal: json['goal'] as String,
      verificationContent: json['verificationContent'] as String?,
      category: json['category'] != null
          ? CrewCategory.fromString(json['category'] as String)
          : null,
      verificationType:
          VerificationType.fromString(json['verificationType'] as String),
      allowLateJoin: json['allowLateJoin'] as bool,
      currentMembers: json['currentMembers'] as int,
      maxMembers: json['maxMembers'] as int,
      status: CrewStatus.fromString(json['status'] as String),
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class SearchCrewResult {
  final List<SearchCrewItem> crews;
  final bool hasNext;

  const SearchCrewResult({
    required this.crews,
    required this.hasNext,
  });

  factory SearchCrewResult.fromJson(Map<String, dynamic> json) {
    return SearchCrewResult(
      crews: (json['crews'] as List)
          .map((e) => SearchCrewItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasNext: json['hasNext'] as bool,
    );
  }
}

class CreateCrewResult {
  final String crewId;
  final String inviteCode;
  final DateTime startDate;

  const CreateCrewResult({
    required this.crewId,
    required this.inviteCode,
    required this.startDate,
  });

  factory CreateCrewResult.fromJson(Map<String, dynamic> json) {
    return CreateCrewResult(
      crewId: json['crewId'] as String,
      inviteCode: json['inviteCode'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
    );
  }
}

class JoinCrewResult {
  final String userId;
  final String crewId;
  final String role;
  final int currentMembers;
  final DateTime joinedAt;

  const JoinCrewResult({
    required this.userId,
    required this.crewId,
    required this.role,
    required this.currentMembers,
    required this.joinedAt,
  });

  factory JoinCrewResult.fromJson(Map<String, dynamic> json) {
    return JoinCrewResult(
      userId: json['userId'] as String,
      crewId: json['crewId'] as String,
      role: json['role'] as String,
      currentMembers: json['currentMembers'] as int,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }
}
