import 'package:triagain/models/crew.dart';
import 'package:triagain/models/challenge.dart';
import 'package:triagain/models/verification.dart';

class MockData {
  MockData._();

  static final List<Crew> crews = [
    Crew(
      id: 'crew_1',
      name: '운동 크루',
      goal: '매일 아침 30분 운동하기',
      maxMembers: 5,
      currentMembers: 3,
      durationDays: 3,
      verificationType: VerificationType.photoRequired,
      allowMidJoin: true,
      status: CrewStatus.inProgress,
      inviteCode: 'ABC123',
      createdAt: DateTime(2026, 2, 20),
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
    Challenge(
      id: 'challenge_1',
      crewId: 'crew_1',
      round: 1,
      startDate: DateTime(2026, 2, 20),
      endDate: DateTime(2026, 2, 23),
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

  static final List<Verification> verifications = [
    Verification(
      id: 'verify_1',
      challengeId: 'challenge_1',
      userId: 'user_1',
      imageUrl: 'https://picsum.photos/200',
      text: '오늘도 30분 달리기 완료!',
      createdAt: DateTime(2026, 2, 20, 18, 30),
      status: VerificationStatus.completed,
    ),
    Verification(
      id: 'verify_2',
      challengeId: 'challenge_1',
      userId: 'user_2',
      imageUrl: 'https://picsum.photos/201',
      text: '헬스장에서 운동했어요',
      createdAt: DateTime(2026, 2, 20, 20, 0),
      status: VerificationStatus.completed,
    ),
    Verification(
      id: 'verify_3',
      challengeId: 'challenge_1',
      userId: 'user_1',
      text: '스트레칭 30분',
      createdAt: DateTime(2026, 2, 21, 19, 0),
      status: VerificationStatus.completed,
    ),
  ];
}
