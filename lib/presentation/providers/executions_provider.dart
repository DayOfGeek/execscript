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
import '../../data/models/execution.dart';
import '../../data/repositories/execution_repository.dart';

/// State for executions
class ExecutionsState {
  final List<Execution> executions;
  final List<Execution> runningExecutions;
  final bool isLoading;
  final String? error;

  const ExecutionsState({
    this.executions = const [],
    this.runningExecutions = const [],
    this.isLoading = false,
    this.error,
  });

  ExecutionsState copyWith({
    List<Execution>? executions,
    List<Execution>? runningExecutions,
    bool? isLoading,
    String? error,
  }) {
    return ExecutionsState(
      executions: executions ?? this.executions,
      runningExecutions: runningExecutions ?? this.runningExecutions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  List<Execution> get recentExecutions {
    final sorted = List<Execution>.from(executions)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return sorted.take(10).toList();
  }
}

/// Provider for executions state
class ExecutionsNotifier extends StateNotifier<ExecutionsState> {
  ExecutionsNotifier() : super(const ExecutionsState()) {
    loadExecutions();
  }

  /// Load all executions from database
  Future<void> loadExecutions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final executions = await ExecutionRepository.getAll(limit: 100);
      final running = await ExecutionRepository.getRunning();
      state = state.copyWith(
        executions: executions,
        runningExecutions: running,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load executions: $e',
      );
    }
  }

  /// Add a new execution
  Future<Execution> addExecution(Execution execution) async {
    state = state.copyWith(isLoading: true);
    try {
      final newExecution = await ExecutionRepository.insert(execution);
      await loadExecutions();
      return newExecution;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add execution: $e',
      );
      rethrow;
    }
  }

  /// Update an execution
  Future<void> updateExecution(Execution execution) async {
    try {
      await ExecutionRepository.update(execution);
      await loadExecutions();
    } catch (e) {
      // Silent refresh failure
    }
  }

  /// Complete an execution
  Future<void> completeExecution(
    int id, {
    required String output,
    required int exitCode,
  }) async {
    try {
      await ExecutionRepository.complete(
        id,
        output: output,
        exitCode: exitCode,
      );
      await loadExecutions();
    } catch (e) {
      // Silent refresh failure
    }
  }

  /// Update execution status
  Future<void> updateStatus(int id, ExecutionStatus status) async {
    try {
      await ExecutionRepository.updateStatus(id, status);
      await loadExecutions();
    } catch (e) {
      // Silent refresh failure
    }
  }

  /// Delete an execution
  Future<void> deleteExecution(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ExecutionRepository.delete(id);
      await loadExecutions();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete execution: $e',
      );
      rethrow;
    }
  }

  /// Refresh only running executions
  Future<void> refreshRunning() async {
    try {
      final running = await ExecutionRepository.getRunning();
      state = state.copyWith(runningExecutions: running);
    } catch (e) {
      // Silent failure
    }
  }
}

/// Global provider for executions
final executionsProvider =
    StateNotifierProvider<ExecutionsNotifier, ExecutionsState>((ref) {
      return ExecutionsNotifier();
    });

/// Provider for a single execution by ID
final executionByIdProvider = Provider.family<Execution?, int>((ref, id) {
  final state = ref.watch(executionsProvider);
  try {
    return state.executions.firstWhere((e) => e.id == id);
  } catch (_) {
    return null;
  }
});

/// Provider for executions by server ID
final executionsByServerProvider = Provider.family<List<Execution>, int>((
  ref,
  serverId,
) {
  final state = ref.watch(executionsProvider);
  return state.executions.where((e) => e.serverId == serverId).toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
});

/// Provider for executions by script ID
final executionsByScriptProvider = Provider.family<List<Execution>, int>((
  ref,
  scriptId,
) {
  final state = ref.watch(executionsProvider);
  return state.executions.where((e) => e.scriptId == scriptId).toList()
    ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
});
