enum ChallengeStatus {
  pending,
  inProgress,
  completed,
  failed,
}

class Challenge {
  final String id;
  final String crewId;
  final int round;
  final DateTime startDate;
  final DateTime endDate;
  final ChallengeStatus status;

  const Challenge({
    required this.id,
    required this.crewId,
    required this.round,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  int get totalDays => endDate.difference(startDate).inDays;

  int get elapsedDays {
    final now = DateTime.now();
    if (now.isBefore(startDate)) return 0;
    if (now.isAfter(endDate)) return totalDays;
    return now.difference(startDate).inDays;
  }
}
