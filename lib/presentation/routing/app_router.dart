import 'package:flutter/foundation.dart';
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
import 'package:byure/presentation/screens/profile/edit_profile_screen.dart';
import 'package:byure/presentation/screens/subscription/paywall_screen.dart';
import 'package:byure/presentation/screens/walk_invite/walk_invite_screen.dart';
import 'package:byure/presentation/screens/routes/routes_screen.dart';
import 'package:byure/presentation/screens/settings/settings_screen.dart';
import 'package:byure/presentation/providers/auth_provider.dart';
import 'package:byure/presentation/screens/chat/chat_screen.dart';
import 'package:byure/domain/entities/chat_entity.dart';
import 'package:byure/services/chat_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Safely watch auth state with error handling
  bool isLoggedIn = false;
  try {
    final authState = ref.watch(authStateProvider);
    isLoggedIn = authState.valueOrNull != null;
  } catch (e) {
    // If auth state fails (e.g., Firebase not initialized), assume not logged in
    debugPrint('Auth state check failed: $e');
    isLoggedIn = false;
  }

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
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
        routes: [
           GoRoute(
             path: ':id',
             builder: (context, state) {
               final chatId = state.pathParameters['id']!;
               final chat = state.extra as ChatEntity?;
               if (chat != null) {
                 return ChatScreen(chatId: chatId, chat: chat);
               }
               // If no extra data (e.g. navigated from ChatListItem without extra),
               // fetch the chat on the fly.
               return _ChatLoader(chatId: chatId);
             },
           ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => const EditProfileScreen(),
          ),
        ],
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

/// A loading widget that fetches chat data from Supabase before opening ChatScreen.
/// This is used when navigating to /chat/:id without passing a ChatEntity as extra.
class _ChatLoader extends StatefulWidget {
  final String chatId;
  const _ChatLoader({required this.chatId});

  @override
  State<_ChatLoader> createState() => _ChatLoaderState();
}

class _ChatLoaderState extends State<_ChatLoader> {
  ChatEntity? _chat;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  Future<void> _loadChat() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) {
        setState(() => _error = 'Not signed in');
        return;
      }

      final data = await supabase
          .from('matches')
          .select('*, user1:users!user_id_1(*), user2:users!user_id_2(*)')
          .eq('id', widget.chatId)
          .maybeSingle();

      if (data == null) {
        setState(() => _error = 'Chat not found');
        return;
      }

      // Build ChatEntity from raw data
      final u1 = data['user_id_1'] as String;
      final u2 = data['user_id_2'] as String;
      final isUser1Me = u1 == currentUserId;
      final otherData = (isUser1Me ? data['user2'] : data['user1']) as Map<String, dynamic>? ?? {};

      setState(() {
        _chat = ChatEntity(
          id: data['id'] as String,
          userId1: u1,
          userId2: u2,
          lastMessage: data['last_message'] as String?,
          lastMessageTime: data['last_message_time'] != null
              ? DateTime.parse(data['last_message_time'] as String)
              : null,
          unreadCount: 0,
          otherUserId: isUser1Me ? u2 : u1,
          otherUserName: otherData['name'] as String?,
          otherUserPhotoUrl: otherData['photo_url'] as String?,
        );
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error loading chat: $_error')),
      );
    }
    if (_chat == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return ChatScreen(chatId: widget.chatId, chat: _chat!);
  }
}



