import 'package:go_router/go_router.dart';
import 'package:triagain/features/auth/screens/login_screen.dart';
import 'package:triagain/features/home/screens/home_screen.dart';
import 'package:triagain/features/crew/screens/create_crew_screen.dart';
import 'package:triagain/features/crew/screens/crew_success_screen.dart';
import 'package:triagain/features/crew/screens/crew_confirm_screen.dart';
import 'package:triagain/features/crew/screens/crew_detail_screen.dart';
import 'package:triagain/features/verification/screens/verification_screen.dart';

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/crew/create',
      builder: (context, state) => const CreateCrewScreen(),
    ),
    GoRoute(
      path: '/crew/success',
      builder: (context, state) => const CrewSuccessScreen(),
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
      builder: (context, state) => VerificationScreen(
        crewId: state.uri.queryParameters['crewId'] ?? '',
      ),
    ),
  ],
);
