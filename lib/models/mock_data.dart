import 'package:triagain/models/crew.dart';
import 'package:triagain/models/challenge.dart';
import 'package:triagain/models/verification.dart';

class MockData {
  MockData._();

  static const Map<String, String> userNames = {
    'user_1': '민수',
    'user_2': '지안',
    'user_3': '수진',
    'user_4': '영희',
  };

  static final List<Crew> crews = [
    Crew(
      id: 'crew_1',
      name: '매일 운동 크루',
      goal: '매일 아침 30분 운동하기',
      maxMembers: 5,
      currentMembers: 4,
      durationDays: 3,
      verificationType: VerificationType.photoRequired,
      allowMidJoin: true,
      status: CrewStatus.inProgress,
      inviteCode: 'ABC123',
      createdAt: DateTime(2026, 2, 15),
      currentDay: 2,
      round: 2,
    ),
    Crew(
      id: 'crew_2',
      name: '독서 크루',
      goal: '매일 책 10페이지 읽기',
      maxMembers: 4,
      currentMembers: 4,
      durationDays: 3,
      verificationType: VerificationType.textOnly,
      allowMidJoin: false,
      status: CrewStatus.inProgress,
      inviteCode: 'DEF456',
      createdAt: DateTime(2026, 2, 21),
      currentDay: 1,
      round: 1,
    ),
  ];

  static final List<Challenge> challenges = [
    // crew_1 round 1: completed
    Challenge(
      id: 'challenge_1',
      crewId: 'crew_1',
      round: 1,
      startDate: DateTime(2026, 2, 17),
      endDate: DateTime(2026, 2, 20),
      status: ChallengeStatus.completed,
    ),
    // crew_1 round 2: in progress
    Challenge(
      id: 'challenge_1b',
      crewId: 'crew_1',
      round: 2,
      startDate: DateTime(2026, 2, 21),
      endDate: DateTime(2026, 2, 24),
      status: ChallengeStatus.inProgress,
    ),
    Challenge(
      id: 'challenge_2',
      crewId: 'crew_2',
      round: 1,
      startDate: DateTime(2026, 2, 22),
      endDate: DateTime(2026, 2, 25),
      status: ChallengeStatus.pending,
    ),
  ];

  static final List<Map<String, dynamic>> crewMembers = [
    {'name': '민수', 'isLeader': true},
    {'name': '지안', 'isLeader': false},
    {'name': '수진', 'isLeader': false},
    {'name': '영희', 'isLeader': false},
  ];

  /// Returns member verification stats for a crew, sorted by rate descending.
  static List<Map<String, dynamic>> getMemberStatsForCrew(String crewId) {
    if (crewId == 'crew_1') {
      return [
        {'name': '민수', 'rate': 100, 'rank': 1},
        {'name': '지안', 'rate': 67, 'rank': 2},
        {'name': '수진', 'rate': 33, 'rank': 3},
        {'name': '영희', 'rate': 17, 'rank': 4},
      ];
    }
    if (crewId == 'crew_2') {
      return [
        {'name': '민수', 'rate': 50, 'rank': 1},
        {'name': '지안', 'rate': 50, 'rank': 2},
        {'name': '수진', 'rate': 25, 'rank': 3},
        {'name': '영희', 'rate': 0, 'rank': 4},
      ];
    }
    return [];
  }

  static Crew? findByInviteCode(String code) {
    try {
      return crews.firstWhere((c) => c.inviteCode == code);
    } catch (_) {
      return null;
    }
  }

  static final List<Verification> verifications = [
    // crew_1 round 1: Feb 17, 18, 19
    Verification(
      id: 'verify_1',
      challengeId: 'challenge_1',
      userId: 'user_1',
      imageUrl: 'https://picsum.photos/200',
      text: '오늘도 30분 달리기 완료!',
      createdAt: DateTime(2026, 2, 17, 18, 30),
      status: VerificationStatus.completed,
    ),
    Verification(
      id: 'verify_2',
      challengeId: 'challenge_1',
      userId: 'user_1',
      imageUrl: 'https://picsum.photos/201',
      text: '헬스장에서 운동했어요',
      createdAt: DateTime(2026, 2, 18, 20, 0),
      status: VerificationStatus.completed,
    ),
    Verification(
      id: 'verify_3',
      challengeId: 'challenge_1',
      userId: 'user_1',
      imageUrl: 'https://picsum.photos/202',
      text: '스트레칭 30분',
      createdAt: DateTime(2026, 2, 19, 19, 0),
      status: VerificationStatus.completed,
    ),
    // crew_1 round 2: Feb 21, 22
    Verification(
      id: 'verify_4',
      challengeId: 'challenge_1b',
      userId: 'user_1',
      imageUrl: 'https://picsum.photos/203',
      text: '아침 조깅 완료!',
      createdAt: DateTime(2026, 2, 21, 7, 30),
      status: VerificationStatus.completed,
    ),
    Verification(
      id: 'verify_5',
      challengeId: 'challenge_1b',
      userId: 'user_1',
      imageUrl: 'https://picsum.photos/204',
      text: '오늘도 운동 성공!',
      createdAt: DateTime(2026, 2, 22, 8, 0),
      status: VerificationStatus.completed,
    ),
    // crew_1 round 2: user_2 verifications
    Verification(
      id: 'verify_6',
      challengeId: 'challenge_1b',
      userId: 'user_2',
      imageUrl: 'https://picsum.photos/205',
      text: '홈트 30분 완료!',
      createdAt: DateTime(2026, 2, 21, 9, 0),
      status: VerificationStatus.completed,
    ),
    Verification(
      id: 'verify_7',
      challengeId: 'challenge_1b',
      userId: 'user_2',
      imageUrl: 'https://picsum.photos/206',
      text: '필라테스 다녀왔어요 💪',
      createdAt: DateTime(2026, 2, 22, 10, 30),
      status: VerificationStatus.completed,
    ),
    // crew_1 round 2: user_3 verifications
    Verification(
      id: 'verify_8',
      challengeId: 'challenge_1b',
      userId: 'user_3',
      imageUrl: 'https://picsum.photos/207',
      text: '공원 산책 30분!',
      createdAt: DateTime(2026, 2, 22, 14, 0),
      status: VerificationStatus.completed,
    ),
    // Today's verifications (2/24)
    Verification(
      id: 'verify_9',
      challengeId: 'challenge_1b',
      userId: 'user_1',
      imageUrl: 'https://picsum.photos/208',
      text: '아침 러닝 3km 완료!',
      createdAt: DateTime(2026, 2, 24, 7, 0),
      status: VerificationStatus.completed,
    ),
    Verification(
      id: 'verify_10',
      challengeId: 'challenge_1b',
      userId: 'user_2',
      imageUrl: 'https://picsum.photos/209',
      text: '오늘은 수영했어요 🏊',
      createdAt: DateTime(2026, 2, 24, 9, 30),
      status: VerificationStatus.completed,
    ),
  ];

  /// Returns verification calendar data for a crew.
  /// Map key: date (year, month, day only)
  /// Map value: true = completed 3-day round (success), false = verified (main)
  static Map<DateTime, bool> getVerificationCalendarData(String crewId) {
    final crewChallenges =
        challenges.where((c) => c.crewId == crewId).toList();
    final result = <DateTime, bool>{};

    for (final challenge in crewChallenges) {
      if (challenge.status == ChallengeStatus.completed) {
        // All days of completed round → success color
        for (int i = 0; i < challenge.totalDays; i++) {
          final date = challenge.startDate.add(Duration(days: i));
          result[DateTime(date.year, date.month, date.day)] = true;
        }
      } else if (challenge.status == ChallengeStatus.inProgress) {
        // Only verified dates → main color
        final challengeVerifications = verifications
            .where((v) => v.challengeId == challenge.id && v.userId == 'user_1');
        for (final v in challengeVerifications) {
          final date =
              DateTime(v.createdAt.year, v.createdAt.month, v.createdAt.day);
          if (!result.containsKey(date)) {
            result[date] = false;
          }
        }
      }
    }

    return result;
  }

  /// Returns all verifications for the current in-progress challenge of a crew,
  /// sorted by createdAt descending (newest first).
  static List<Verification> getFeedForCrew(String crewId) {
    final activeChallenges = challenges.where(
      (c) =>
          c.crewId == crewId &&
          (c.status == ChallengeStatus.inProgress ||
              c.status == ChallengeStatus.completed),
    );
    if (activeChallenges.isEmpty) return [];

    final challengeIds = activeChallenges.map((c) => c.id).toSet();
    final feed = verifications
        .where((v) => challengeIds.contains(v.challengeId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return feed;
  }
}
