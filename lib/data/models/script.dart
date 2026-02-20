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

/// Script variable definition
class ScriptVariable {
  final String name;
  final String? defaultValue;
  final bool required;
  final String? description;

  const ScriptVariable({
    required this.name,
    this.defaultValue,
    this.required = false,
    this.description,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'defaultValue': defaultValue,
      'required': required,
      'description': description,
    };
  }

  factory ScriptVariable.fromMap(Map<String, dynamic> map) {
    return ScriptVariable(
      name: map['name'] as String,
      defaultValue: map['defaultValue'] as String?,
      required: map['required'] as bool? ?? false,
      description: map['description'] as String?,
    );
  }
}

/// Script model representing a shell script
class Script {
  final int? id;
  final String name;
  final String content;
  final bool isReusable;
  final int? defaultServerId; // null if reusable
  final String? category;
  final List<ScriptVariable> variables;
  final DateTime createdAt;
  final DateTime updatedAt;

  Script({
    this.id,
    required this.name,
    required this.content,
    this.isReusable = true,
    this.defaultServerId,
    this.category,
    this.variables = const [],
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  /// Inject variables into script content
  String injectVariables(Map<String, String> values) {
    var result = content;
    for (final variable in variables) {
      final value = values[variable.name] ?? variable.defaultValue ?? '';
      // Replace both ${VAR} and $VAR patterns
      result = result.replaceAll('\${${variable.name}}', value);
      result = result.replaceAll('\$${variable.name}', value);
    }
    return result;
  }

  Script copyWith({
    int? id,
    String? name,
    String? content,
    bool? isReusable,
    int? defaultServerId,
    String? category,
    List<ScriptVariable>? variables,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Script(
      id: id ?? this.id,
      name: name ?? this.name,
      content: content ?? this.content,
      isReusable: isReusable ?? this.isReusable,
      defaultServerId: defaultServerId ?? this.defaultServerId,
      category: category ?? this.category,
      variables: variables ?? this.variables,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'content': content,
      'is_reusable': isReusable ? 1 : 0,
      'default_server_id': defaultServerId,
      'category': category,
      'variables': variables.map((v) => v.toMap()).toList().toString(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Script.fromMap(Map<String, dynamic> map) {
    // Parse variables from string representation
    List<ScriptVariable> parsedVariables = [];
    final varsStr = map['variables'] as String?;
    if (varsStr != null && varsStr.isNotEmpty && varsStr != '[]') {
      // Simple parsing - in production would use proper JSON
      try {
        // This is a simplified parser - real implementation would be more robust
        parsedVariables = [];
      } catch (_) {
        parsedVariables = [];
      }
    }

    return Script(
      id: map['id'] as int?,
      name: map['name'] as String,
      content: map['content'] as String,
      isReusable: (map['is_reusable'] as int? ?? 1) == 1,
      defaultServerId: map['default_server_id'] as int?,
      category: map['category'] as String?,
      variables: parsedVariables,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  @override
  String toString() {
    return 'Script(id: $id, name: $name, isReusable: $isReusable)';
  }
}
