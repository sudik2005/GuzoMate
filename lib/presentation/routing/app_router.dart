import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:byure/presentation/screens/splash_screen.dart';
import 'package:byure/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:byure/presentation/screens/auth/login_screen.dart';
import 'package:byure/presentation/screens/auth/signup_screen.dart';
import 'package:byure/presentation/screens/home/home_screen.dart';
import 'package:byure/presentation/screens/map/map_screen.dart';
import 'package:byure/presentation/screens/matches/matches_screen.dart';
import 'package:byure/presentation/screens/chat/chat_list_screen.dart';
import 'package:byure/presentation/screens/profile/profile_screen.dart';
import 'package:byure/presentation/screens/subscription/paywall_screen.dart';
import 'package:byure/presentation/screens/walk_invite/walk_invite_screen.dart';
import 'package:byure/presentation/screens/routes/routes_screen.dart';
import 'package:byure/presentation/screens/settings/settings_screen.dart';
import 'package:byure/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnOnboarding = state.matchedLocation == '/onboarding';
      final isOnAuth = state.matchedLocation.startsWith('/auth');

      if (isOnSplash || isOnOnboarding) {
        return null;
      }

      if (!isLoggedIn && !isOnAuth) {
        return '/auth/login';
      }

      if (isLoggedIn && isOnAuth) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/map',
        builder: (context, state) => const MapScreen(),
      ),
      GoRoute(
        path: '/matches',
        builder: (context, state) => const MatchesScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/walk-invite/:userId',
        builder: (context, state) {
          final userId = state.pathParameters['userId']!;
          return WalkInviteScreen(userId: userId);
        },
      ),
      GoRoute(
        path: '/routes',
        builder: (context, state) => const RoutesScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});


