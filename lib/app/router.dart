import 'package:go_router/go_router.dart';
import 'package:triagain/features/auth/screens/login_screen.dart';
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
          crewName: state.uri.queryParameters['crewName'] ?? '',
        ),
      ),
      GoRoute(
        path: '/crew/confirm',
        builder: (context, state) => CrewConfirmScreen(
          crewId: state.uri.queryParameters['crewId'] ?? '',
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
