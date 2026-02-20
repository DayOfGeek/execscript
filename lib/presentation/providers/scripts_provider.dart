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
import '../../data/models/script.dart';
import '../../data/repositories/script_repository.dart';

/// State for scripts list
class ScriptsState {
  final List<Script> scripts;
  final bool isLoading;
  final String? error;
  final String? selectedCategory;

  const ScriptsState({
    this.scripts = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategory,
  });

  ScriptsState copyWith({
    List<Script>? scripts,
    bool? isLoading,
    String? error,
    String? selectedCategory,
  }) {
    return ScriptsState(
      scripts: scripts ?? this.scripts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategory: selectedCategory ?? this.selectedCategory,
    );
  }

  List<Script> get reusableScripts =>
      scripts.where((s) => s.isReusable).toList();

  List<Script> get serverSpecificScripts =>
      scripts.where((s) => !s.isReusable).toList();

  List<String> get categories {
    final cats = scripts
        .where((s) => s.category != null && s.category!.isNotEmpty)
        .map((s) => s.category!)
        .toSet()
        .toList();
    cats.sort();
    return cats;
  }
}

/// Provider for scripts state
class ScriptsNotifier extends StateNotifier<ScriptsState> {
  ScriptsNotifier() : super(const ScriptsState()) {
    loadScripts();
  }

  /// Load all scripts from database
  Future<void> loadScripts() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final scripts = await ScriptRepository.getAll();
      state = state.copyWith(scripts: scripts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load scripts: $e',
      );
    }
  }

  /// Add a new script
  Future<Script> addScript(Script script) async {
    state = state.copyWith(isLoading: true);
    try {
      final newScript = await ScriptRepository.insert(script);
      await loadScripts();
      return newScript;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add script: $e',
      );
      rethrow;
    }
  }

  /// Update an existing script
  Future<void> updateScript(Script script) async {
    state = state.copyWith(isLoading: true);
    try {
      await ScriptRepository.update(script);
      await loadScripts();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update script: $e',
      );
      rethrow;
    }
  }

  /// Delete a script
  Future<void> deleteScript(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ScriptRepository.delete(id);
      await loadScripts();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete script: $e',
      );
      rethrow;
    }
  }

  /// Select category filter
  void selectCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
  }
}

/// Global provider for scripts
final scriptsProvider = StateNotifierProvider<ScriptsNotifier, ScriptsState>((
  ref,
) {
  return ScriptsNotifier();
});

/// Provider for a single script by ID
final scriptByIdProvider = Provider.family<Script?, int>((ref, id) {
  final state = ref.watch(scriptsProvider);
  try {
    return state.scripts.firstWhere((s) => s.id == id);
  } catch (_) {
    return null;
  }
});

/// Provider for scripts available to a specific server
final scriptsForServerProvider = Provider.family<List<Script>, int>((
  ref,
  serverId,
) {
  final state = ref.watch(scriptsProvider);
  return state.scripts
      .where((s) => s.isReusable || s.defaultServerId == serverId)
      .toList();
});
