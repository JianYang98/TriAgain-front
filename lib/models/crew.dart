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
    );
  }
}

class CrewMember {
  final String userId;
  final String role;
  final DateTime joinedAt;

  const CrewMember({
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory CrewMember.fromJson(Map<String, dynamic> json) {
    return CrewMember(
      userId: json['userId'] as String,
      role: json['role'] as String,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  bool get isLeader => role == 'LEADER';
}

class CrewDetail {
  final String id;
  final String creatorId;
  final String name;
  final String goal;
  final VerificationType verificationType;
  final int maxMembers;
  final int currentMembers;
  final CrewStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final bool allowLateJoin;
  final String inviteCode;
  final DateTime createdAt;
  final List<CrewMember> members;
  final String? deadlineTime;

  const CrewDetail({
    required this.id,
    required this.creatorId,
    required this.name,
    required this.goal,
    required this.verificationType,
    required this.maxMembers,
    required this.currentMembers,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.allowLateJoin,
    required this.inviteCode,
    required this.createdAt,
    required this.members,
    this.deadlineTime,
  });

  factory CrewDetail.fromJson(Map<String, dynamic> json) {
    return CrewDetail(
      id: json['id'] as String,
      creatorId: json['creatorId'] as String,
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
      inviteCode: json['inviteCode'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      members: (json['members'] as List)
          .map((m) => CrewMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      deadlineTime: json['deadlineTime'] as String?,
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
