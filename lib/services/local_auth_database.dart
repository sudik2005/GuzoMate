import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Handles user credential storage and session tracking using SQLite.
class LocalAuthDatabase {
  LocalAuthDatabase._internal();
  static final LocalAuthDatabase _instance = LocalAuthDatabase._internal();

  factory LocalAuthDatabase() => _instance;

  static const _dbName = 'byure_auth.db';
  static const _dbVersion = 1;

  static const _userTable = 'users';
  static const _sessionTable = 'sessions';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);

    return openDatabase(
      path,
      version: _dbVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_userTable (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL,
            name TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE $_sessionTable (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            created_at TEXT NOT NULL,
            FOREIGN KEY (user_id) REFERENCES $_userTable (id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }

  Future<String> createUser({
    required String email,
    required String passwordHash,
    String? name,
  }) async {
    final db = await database;
    final userId = const Uuid().v4();

    await db.insert(
      _userTable,
      {
        'id': userId,
        'email': email,
        'password_hash': passwordHash,
        'name': name,
        'created_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.abort,
    );

    return userId;
  }

  Future<DbUser?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'email = ?',
      whereArgs: [email],
      limit: 1,
    );

    if (result.isEmpty) return null;
    return DbUser.fromMap(result.first);
  }

  Future<DbUser?> getUserById(String id) async {
    final db = await database;
    final result = await db.query(
      _userTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (result.isEmpty) return null;
    return DbUser.fromMap(result.first);
  }

  Future<void> updatePasswordHash({
    required String userId,
    required String passwordHash,
  }) async {
    final db = await database;
    await db.update(
      _userTable,
      {
        'password_hash': passwordHash,
      },
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete(
      _userTable,
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> upsertSession(String userId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete(_sessionTable);
      await txn.insert(_sessionTable, {
        'user_id': userId,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
  }

  Future<String?> getActiveSessionUserId() async {
    final db = await database;
    final result = await db.query(
      _sessionTable,
      orderBy: 'created_at DESC',
      limit: 1,
    );

    if (result.isEmpty) return null;
    return result.first['user_id'] as String;
  }

  Future<void> clearSession() async {
    final db = await database;
    await db.delete(_sessionTable);
  }
}

class DbUser {
  final String id;
  final String email;
  final String passwordHash;
  final String? name;
  final DateTime createdAt;

  DbUser({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    required this.createdAt,
  });

  factory DbUser.fromMap(Map<String, Object?> map) {
    return DbUser(
      id: map['id'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      name: map['name'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}


