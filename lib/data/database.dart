// ExecScript - Mobile SSH Script Execution
// Copyright (C) 2026 DayOfGeek.com
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.

import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../core/constants.dart';

/// Database helper for SQLite operations
class DatabaseHelper {
  static Database? _database;

  /// Get the database instance
  static Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  /// Initialize the database
  static Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// Create database tables
  static Future _onCreate(Database db, int version) async {
    // Servers table
    await db.execute('''
      CREATE TABLE servers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        hostname TEXT NOT NULL,
        port INTEGER DEFAULT 22,
        username TEXT NOT NULL,
        auth_type TEXT NOT NULL,
        credential_key TEXT NOT NULL,
        key_fingerprint TEXT,
        preferred_shell TEXT DEFAULT 'tmux',
        tags TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        last_connected TEXT
      )
    ''');

    // Scripts table
    await db.execute('''
      CREATE TABLE scripts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        content TEXT NOT NULL,
        is_reusable INTEGER DEFAULT 1,
        default_server_id INTEGER,
        category TEXT,
        variables TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (default_server_id) REFERENCES servers(id) ON DELETE SET NULL
      )
    ''');

    // Executions table
    await db.execute('''
      CREATE TABLE executions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NOT NULL,
        script_id INTEGER NOT NULL,
        mode TEXT NOT NULL,
        tmux_session_name TEXT,
        status TEXT NOT NULL,
        output TEXT,
        exit_code INTEGER,
        variables_used TEXT,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE,
        FOREIGN KEY (script_id) REFERENCES scripts(id) ON DELETE SET NULL
      )
    ''');

    // Create indexes for performance
    await db.execute(
      'CREATE INDEX idx_executions_server ON executions(server_id)',
    );
    await db.execute(
      'CREATE INDEX idx_executions_script ON executions(script_id)',
    );
    await db.execute(
      'CREATE INDEX idx_executions_status ON executions(status)',
    );
    await db.execute(
      'CREATE INDEX idx_executions_started ON executions(started_at)',
    );
    await db.execute('CREATE INDEX idx_servers_name ON servers(name)');
  }

  /// Handle database upgrades
  static Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle future migrations here
    if (oldVersion < 2) {
      // Migration for version 2
    }
  }

  /// Close the database
  static Future close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// Delete the database (for testing or reset)
  static Future deleteDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, AppConstants.databaseName);
    await databaseFactory.deleteDatabase(path);
    _database = null;
  }
}
