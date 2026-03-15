import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:triagain/features/auth/screens/login_screen.dart';
import 'package:triagain/providers/auth_provider.dart';
import 'package:triagain/features/auth/screens/onboarding_screen.dart';
import 'package:triagain/features/auth/screens/terms_detail_screen.dart';
import 'package:triagain/features/home/screens/home_screen.dart';
import 'package:triagain/features/crew/screens/create_crew_screen.dart';
import 'package:triagain/features/crew/screens/crew_success_screen.dart';
import 'package:triagain/features/crew/screens/crew_confirm_screen.dart';
import 'package:triagain/features/crew/screens/crew_detail_screen.dart';
import 'package:triagain/features/mypage/screens/mypage_screen.dart';
import 'package:triagain/features/verification/screens/verification_screen.dart';

GoRouter createRouter({String initialLocation = '/login'}) {
  return GoRouter(
    initialLocation: initialLocation,
    onException: (context, state, router) {
      if (state.uri.toString().startsWith('kakao')) {
        // 카카오 SDK가 이 URL을 먼저 처리해서 이미 로그인 완료됨.
        // Riverpod 상태를 보고 올바른 화면으로 이동.
        final container = ProviderScope.containerOf(context);
        final token = container.read(authTokenProvider);
        final kakaoToken = container.read(kakaoAccessTokenProvider);

        if (token != null) {
          router.go('/home');       // 기존 유저 — 이미 로그인됨
        } else if (kakaoToken != null) {
          router.go('/onboarding'); // 신규 유저 — 온보딩 진행 중
        } else {
          router.go('/login');      // 폴백
        }
        return;
      }
      router.go('/home'); // 그 외 알 수 없는 경로는 홈으로 fallback
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/terms/:type',
        builder: (context, state) => TermsDetailScreen(
          termsType: state.pathParameters['type'] ?? 'service',
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/mypage',
        builder: (context, state) => const MyPageScreen(),
      ),
      GoRoute(
        path: '/crew/create',
        builder: (context, state) => const CreateCrewScreen(),
      ),
      GoRoute(
        path: '/crew/success',
        builder: (context, state) => CrewSuccessScreen(
          inviteCode: state.uri.queryParameters['inviteCode'] ?? '',
          startDate: state.uri.queryParameters['startDate'] ?? '',
          endDate: state.uri.queryParameters['endDate'] ?? '',
          crewName: state.uri.queryParameters['crewName'] ?? '',
          goal: state.uri.queryParameters['goal'] ?? '',
          verificationContent: state.uri.queryParameters['verificationContent'] ?? '',
        ),
      ),
      GoRoute(
        path: '/crew/confirm',
        builder: (context, state) => CrewConfirmScreen(
          crewId: state.uri.queryParameters['crewId'] ?? '',
          inviteCode: state.uri.queryParameters['inviteCode'],
        ),
      ),
      GoRoute(
        path: '/crew/:id',
        builder: (context, state) => CrewDetailScreen(
          crewId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/verification',
        builder: (context, state) {
          final rawChallengeId = state.uri.queryParameters['challengeId'];
          return VerificationScreen(
            crewId: state.uri.queryParameters['crewId'] ?? '',
            challengeId: (rawChallengeId == null || rawChallengeId.isEmpty)
                ? null
                : rawChallengeId,
          );
        },
      ),
    ],
  );
}
