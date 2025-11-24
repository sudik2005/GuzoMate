import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:byure/services/local_auth_database.dart';

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
}

/// Authentication service backed by a local SQLite database.
class AuthService {
  AuthService({LocalAuthDatabase? database}) : _database = database ?? LocalAuthDatabase() {
    _restoreSession();
  }

  final LocalAuthDatabase _database;
  final _authStateController = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  AuthUser? get currentUser => _currentUser;
  Stream<AuthUser?> get authStateChanges => _authStateController.stream;

  void dispose() {
    _authStateController.close();
  }

  Future<AuthUser> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final existingUser = await _database.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('An account already exists for that email.');
    }

    final userId = await _database.createUser(
      email: email,
      passwordHash: _hashPassword(password),
      name: name,
    );

    final authUser = AuthUser(id: userId, email: email, name: name);
    await _database.upsertSession(userId);
    _setCurrentUser(authUser);
    return authUser;
  }

  Future<AuthUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final dbUser = await _database.getUserByEmail(email);
    if (dbUser == null) {
      throw Exception('No user found for that email.');
    }

    final providedHash = _hashPassword(password);
    if (dbUser.passwordHash != providedHash) {
      throw Exception('Incorrect password.');
    }

    final authUser = AuthUser(id: dbUser.id, email: dbUser.email, name: dbUser.name);
    await _database.upsertSession(dbUser.id);
    _setCurrentUser(authUser);
    return authUser;
  }

  Future<void> signOut() async {
    await _database.clearSession();
    _setCurrentUser(null);
  }

  Future<void> sendPasswordResetEmail(String email) async {
    final dbUser = await _database.getUserByEmail(email);
    if (dbUser == null) {
      throw Exception('No user found for that email.');
    }
    throw Exception('Password reset email is unavailable in offline mode.');
  }

  Future<void> updatePassword(String newPassword) async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('You must be signed in to update your password.');
    }

    await _database.updatePasswordHash(
      userId: user.id,
      passwordHash: _hashPassword(newPassword),
    );
  }

  Future<void> deleteAccount() async {
    final user = _currentUser;
    if (user == null) {
      throw Exception('No active user session.');
    }

    await _database.deleteUser(user.id);
    await _database.clearSession();
    _setCurrentUser(null);
  }

  Future<void> _restoreSession() async {
    final userId = await _database.getActiveSessionUserId();
    if (userId == null) {
      _setCurrentUser(null);
      return;
    }

    final dbUser = await _database.getUserById(userId);
    if (dbUser == null) {
      await _database.clearSession();
      _setCurrentUser(null);
      return;
    }

    final authUser = AuthUser(
      id: dbUser.id,
      email: dbUser.email,
      name: dbUser.name,
    );
    _setCurrentUser(authUser);
  }

  void _setCurrentUser(AuthUser? user) {
    _currentUser = user;
    _authStateController.add(user);
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
