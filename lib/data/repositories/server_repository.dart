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
import '../models/server.dart';
import '../../services/credential_service.dart';

/// Repository for server CRUD operations
class ServerRepository {
  /// Get all servers
  static Future<List<Server>> getAll() async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('servers', orderBy: 'name ASC');
    return maps.map((m) => Server.fromMap(m)).toList();
  }

  /// Get a server by ID
  static Future<Server?> getById(int id) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query('servers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Server.fromMap(maps.first);
  }

  /// Insert a new server
  static Future<Server> insert(Server server) async {
    final db = await DatabaseHelper.database;

    // Generate credential key if not set
    final credentialKey = server.credentialKey.isEmpty
        ? CredentialService.generateCredentialKey(null)
        : server.credentialKey;

    final serverWithKey = server.copyWith(credentialKey: credentialKey);
    final id = await db.insert('servers', serverWithKey.toMap());

    // Update credential key with actual ID
    final finalKey = CredentialService.generateCredentialKey(id);
    await db.update(
      'servers',
      {'credential_key': finalKey},
      where: 'id = ?',
      whereArgs: [id],
    );

    return serverWithKey.copyWith(id: id, credentialKey: finalKey);
  }

  /// Update a server
  static Future<void> update(Server server) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'servers',
      server.toMap(),
      where: 'id = ?',
      whereArgs: [server.id],
    );
  }

  /// Delete a server
  static Future<void> delete(int id) async {
    final db = await DatabaseHelper.database;

    // Get server to find credential key
    final server = await getById(id);
    if (server != null) {
      // Delete credential from secure storage
      await CredentialService.deleteCredential(server.credentialKey);
    }

    await db.delete('servers', where: 'id = ?', whereArgs: [id]);
  }

  /// Update last connected timestamp
  static Future<void> updateLastConnected(int id) async {
    final db = await DatabaseHelper.database;
    await db.update(
      'servers',
      {'last_connected': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Search servers by name or hostname
  static Future<List<Server>> search(String query) async {
    final db = await DatabaseHelper.database;
    final maps = await db.query(
      'servers',
      where: 'name LIKE ? OR hostname LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((m) => Server.fromMap(m)).toList();
  }
}
