import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Lightweight auth user representation used throughout the UI.
class AuthUser {
  final String id;
  final String email;
  final String? name;

  const AuthUser({
    required this.id,
    required this.email,
    this.name,
  });

  factory AuthUser.fromSupabase(User user) {
    return AuthUser(
      id: user.id,
      email: user.email ?? '',
      name: user.userMetadata?['name'] as String?,
    );
  }
}

/// Authentication service backed by Supabase Auth.
class AuthService {
  AuthService() {
    _initialize();
  }

  final _supabase = Supabase.instance.client;
  final _authStateController = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;
  
  // Keep track of auth subscription to cancel on dispose
  StreamSubscription<AuthState>? _authSubscription;

  AuthUser? get currentUser => _currentUser;
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  void _initialize() {
    // Listen to Supabase Auth State Changes
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) {
      final Session? session = data.session;
      final User? user = session?.user;
      
      if (user != null) {
        final authUser = AuthUser.fromSupabase(user);
        _setCurrentUser(authUser);
      } else {
        _setCurrentUser(null);
      }
    });
    
    // Check initial session
    final session = _supabase.auth.currentSession;
    if (session?.user != null) {
      _setCurrentUser(AuthUser.fromSupabase(session!.user));
    }
  }

  void dispose() {
    _authSubscription?.cancel();
    _authStateController.close();
  }

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final response = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: name != null ? {'name': name} : null,
    );
    
    if (response.user == null) {
      throw Exception('Sign up failed: Unknown error');
    }
    
    // Supabase auto-signs in after signup usually, but let's return the user
    return AuthUser.fromSupabase(response.user!);
  }

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
    
    if (response.user == null) {
      throw Exception('Sign in failed');
    }

    return AuthUser.fromSupabase(response.user!);
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
    _setCurrentUser(null);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    await _supabase.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabase.auth.updateUser(UserAttributes(
      password: newPassword,
    ));
  }

  Future<void> deleteAccount() async {
    // Note: Deleting user usually requires admin privileges or specific RLS settings
    // Alternatively, we can just sign them out.
    // For now, let's just sign out as client-side delete is restricted by default.
    await signOut();
    // Implementation for Service Role would be: _supabase.auth.admin.deleteUser(uid)
  }

  void _setCurrentUser(AuthUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }
}

