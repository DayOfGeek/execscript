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

import '../database.dart';
import '../models/script.dart';

/// Repository for script CRUD operations
class ScriptRepository {
  /// Get all scripts
  static Future<List<Script>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('scripts', orderBy: 'name ASC');
    return maps.map((m) => Script.fromMap(m)).toList();
  }

  /// Get reusable scripts only
  static Future<List<Script>> getReusable() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'scripts',
      where: 'is_reusable = ?',
      whereArgs: [1],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Script.fromMap(m)).toList();
  }

  /// Get server-specific scripts
  static Future<List<Script>> getByServer(int serverId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'scripts',
      where: 'default_server_id = ?',
      whereArgs: [serverId],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Script.fromMap(m)).toList();
  }

  /// Get scripts available to a server (reusable + server-specific)
  static Future<List<Script>> getAvailableToServer(int serverId) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'scripts',
      where: 'is_reusable = ? OR default_server_id = ?',
      whereArgs: [1, serverId],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Script.fromMap(m)).toList();
  }

  /// Get a script by ID
  static Future<Script?> getById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('scripts', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Script.fromMap(maps.first);
  }

  /// Insert a new script
  static Future<Script> insert(Script script) async {
    final db = await DatabaseHelper.database;
    final id = await db.insert('scripts', script.toMap());
    return script.copyWith(id: id);
  }

  /// Update a script
  static Future<void> update(Script script) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'scripts',
      script.toMap(),
      where: 'id = ?',
      whereArgs: [script.id],
    );
  }

  /// Delete a script
  static Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('scripts', where: 'id = ?', whereArgs: [id]);
  }

  /// Get scripts by category
  static Future<List<Script>> getByCategory(String category) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'scripts',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Script.fromMap(m)).toList();
  }

  /// Search scripts by name
  static Future<List<Script>> search(String query) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'scripts',
      where: 'name LIKE ?',
      whereArgs: ['%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Script.fromMap(m)).toList();
  }
}
