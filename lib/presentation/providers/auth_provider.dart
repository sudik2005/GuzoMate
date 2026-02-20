import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:byure/services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  final service = AuthService();
  ref.onDispose(service.dispose);
  return service;
});

final authStateProvider = StreamProvider<AuthUser?>((ref) {
  try {
    final authService = ref.watch(authServiceProvider);
    return authService.authStateChanges;
  } catch (e) {
    // Return empty stream if auth service fails
    return Stream.value(null);
  }
});

final currentUserProvider = Provider<AuthUser?>((ref) {
  try {
    final authState = ref.watch(authStateProvider);
    return authState.valueOrNull;
  } catch (e) {
    // If auth state fails, return null
    return null;
  }
});


