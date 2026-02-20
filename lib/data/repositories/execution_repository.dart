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
import '../models/execution.dart';

/// Repository for execution CRUD operations
class ExecutionRepository {
  /// Get all executions
  static Future<List<Execution>> getAll({int limit = 100}) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'executions',
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((m) => Execution.fromMap(m)).toList();
  }

  /// Get executions for a server
  static Future<List<Execution>> getByServer(
    int serverId, {
    int limit = 50,
  }) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'executions',
      where: 'server_id = ?',
      whereArgs: [serverId],
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((m) => Execution.fromMap(m)).toList();
  }

  /// Get executions for a script
  static Future<List<Execution>> getByScript(
    int scriptId, {
    int limit = 50,
  }) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'executions',
      where: 'script_id = ?',
      whereArgs: [scriptId],
      orderBy: 'started_at DESC',
      limit: limit,
    );
    return maps.map((m) => Execution.fromMap(m)).toList();
  }

  /// Get running executions
  static Future<List<Execution>> getRunning() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'executions',
      where: 'status IN (?, ?)',
      whereArgs: ['pending', 'running'],
      orderBy: 'started_at DESC',
    );
    return maps.map((m) => Execution.fromMap(m)).toList();
  }

  /// Get a execution by ID
  static Future<Execution?> getById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('executions', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Execution.fromMap(maps.first);
  }

  /// Insert a new execution
  static Future<Execution> insert(Execution execution) async {
    final db = await DatabaseHelper.database;
    final id = await db.insert('executions', execution.toMap());
    return execution.copyWith(id: id);
  }

  /// Update an execution
  static Future<void> update(Execution execution) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'executions',
      execution.toMap(),
      where: 'id = ?',
      whereArgs: [execution.id],
    );
  }

  /// Update status only
  static Future<void> updateStatus(int id, ExecutionStatus status) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'executions',
      {
        'status': status.name,
        if (status == ExecutionStatus.completed ||
            status == ExecutionStatus.failed ||
            status == ExecutionStatus.cancelled)
          'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Update output
  static Future<void> updateOutput(int id, String output) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'executions',
      {'output': output},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Complete execution with output and exit code
  static Future<void> complete(
    int id, {
    required String output,
    required int exitCode,
  }) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'executions',
      {
        'status': exitCode == 0
            ? ExecutionStatus.completed.name
            : ExecutionStatus.failed.name,
        'output': output,
        'exit_code': exitCode,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete an execution
  static Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;
    await db.delete('executions', where: 'id = ?', whereArgs: [id]);
  }

  /// Delete old executions (cleanup)
  static Future<void> deleteOlderThan(DateTime date) async {
    final db = await DatabaseHelper.database;
    await db.delete(
      'executions',
      where: 'started_at < ?',
      whereArgs: [date.toIso8601String()],
    );
  }
}
