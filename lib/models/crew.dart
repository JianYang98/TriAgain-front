enum CrewStatus {
  recruiting,
  inProgress,
  completed,
}

enum VerificationType {
  textOnly,
  photoRequired,
}

class Crew {
  final String id;
  final String name;
  final String goal;
  final int maxMembers;
  final int currentMembers;
  final int durationDays;
  final VerificationType verificationType;
  final bool allowMidJoin;
  final CrewStatus status;
  final String inviteCode;
  final DateTime createdAt;
  final int currentDay;
  final int round;

  const Crew({
    required this.id,
    required this.name,
    required this.goal,
    required this.maxMembers,
    required this.currentMembers,
    required this.durationDays,
    required this.verificationType,
    required this.allowMidJoin,
    required this.status,
    required this.inviteCode,
    required this.createdAt,
    this.currentDay = 1,
    this.round = 1,
  });
}
