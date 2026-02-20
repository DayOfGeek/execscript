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


import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/server.dart';
import '../../data/repositories/server_repository.dart';

/// State for servers list
class ServersState {
  final List<Server> servers;
  final bool isLoading;
  final String? error;

  const ServersState({
    this.servers = const [],
    this.isLoading = false,
    this.error,
  });

  ServersState copyWith({
    List<Server>? servers,
    bool? isLoading,
    String? error,
  }) {
    return ServersState(
      servers: servers ?? this.servers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider for servers state
class ServersNotifier extends StateNotifier<ServersState> {
  ServersNotifier() : super(const ServersState()) {
    loadServers();
  }

  /// Load all servers from database
  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final servers = await ServerRepository.getAll();
      state = state.copyWith(servers: servers, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load servers: $e',
      );
    }
  }

  /// Add a new server
  Future<Server> addServer(Server server) async {
    state = state.copyWith(isLoading: true);
    try {
      final newServer = await ServerRepository.insert(server);
      await loadServers();
      return newServer;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add server: $e',
      );
      rethrow;
    }
  }

  /// Update an existing server
  Future<void> updateServer(Server server) async {
    state = state.copyWith(isLoading: true);
    try {
      await ServerRepository.update(server);
      await loadServers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update server: $e',
      );
      rethrow;
    }
  }

  /// Delete a server
  Future<void> deleteServer(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ServerRepository.delete(id);
      await loadServers();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete server: $e',
      );
      rethrow;
    }
  }

  /// Update last connected timestamp
  Future<void> updateLastConnected(int id) async {
    try {
      await ServerRepository.updateLastConnected(id);
      await loadServers();
    } catch (e) {
      // Non-critical, don't change loading state
    }
  }
}

/// Global provider for servers
final serversProvider = StateNotifierProvider<ServersNotifier, ServersState>((
  ref,
) {
  return ServersNotifier();
});

/// Provider for a single server by ID
final serverByIdProvider = Provider.family<Server?, int>((ref, id) {
  final state = ref.watch(serversProvider);
  try {
    return state.servers.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});
