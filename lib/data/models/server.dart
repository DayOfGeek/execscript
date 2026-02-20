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

/// Authentication type for SSH connections
enum AuthType { password, key }

/// Preferred shell multiplexer for background execution
enum PreferredShell { tmux, screen, none }

/// Server model representing a Linux host
class Server {
  final int? id;
  final String name;
  final String hostname;
  final int port;
  final String username;
  final AuthType authType;
  final String credentialKey; // Reference to secure storage
  final String? keyFingerprint; // For host verification
  final PreferredShell preferredShell;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastConnected;

  Server({
    this.id,
    required this.name,
    required this.hostname,
    this.port = 22,
    required this.username,
    required this.authType,
    required this.credentialKey,
    this.keyFingerprint,
    this.preferredShell = PreferredShell.tmux,
    this.tags = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
    this.lastConnected,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  Server copyWith({
    int? id,
    String? name,
    String? hostname,
    int? port,
    String? username,
    AuthType? authType,
    String? credentialKey,
    String? keyFingerprint,
    PreferredShell? preferredShell,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastConnected,
  }) {
    return Server(
      id: id ?? this.id,
      name: name ?? this.name,
      hostname: hostname ?? this.hostname,
      port: port ?? this.port,
      username: username ?? this.username,
      authType: authType ?? this.authType,
      credentialKey: credentialKey ?? this.credentialKey,
      keyFingerprint: keyFingerprint ?? this.keyFingerprint,
      preferredShell: preferredShell ?? this.preferredShell,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastConnected: lastConnected ?? this.lastConnected,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'hostname': hostname,
      'port': port,
      'username': username,
      'auth_type': authType.name,
      'credential_key': credentialKey,
      'key_fingerprint': keyFingerprint,
      'preferred_shell': preferredShell.name,
      'tags': tags.join(','),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'last_connected': lastConnected?.toIso8601String(),
    };
  }

  factory Server.fromMap(Map<String, dynamic> map) {
    return Server(
      id: map['id'] as int?,
      name: map['name'] as String,
      hostname: map['hostname'] as String,
      port: map['port'] as int? ?? 22,
      username: map['username'] as String,
      authType: AuthType.values.firstWhere(
        (e) => e.name == map['auth_type'],
        orElse: () => AuthType.password,
      ),
      credentialKey: map['credential_key'] as String,
      keyFingerprint: map['key_fingerprint'] as String?,
      preferredShell: PreferredShell.values.firstWhere(
        (e) => e.name == map['preferred_shell'],
        orElse: () => PreferredShell.tmux,
      ),
      tags: (map['tags'] as String? ?? '').isNotEmpty
          ? (map['tags'] as String).split(',')
          : [],
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      lastConnected: map['last_connected'] != null
          ? DateTime.parse(map['last_connected'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'Server(id: $id, name: $name, hostname: $hostname:$port)';
  }
}
