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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme.dart';
import '../../data/models/script.dart';
import '../../data/models/server.dart';
import '../../data/repositories/server_repository.dart';
import '../providers/scripts_provider.dart';

/// Form for creating or editing a script
class ScriptForm extends ConsumerStatefulWidget {
  final Script? script;
  final bool? initialIsReusable;

  const ScriptForm({super.key, this.script, this.initialIsReusable});

  @override
  ConsumerState<ScriptForm> createState() => _ScriptFormState();
}

class _ScriptFormState extends ConsumerState<ScriptForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _contentController = TextEditingController();

  bool _isReusable = true;
  int? _selectedServerId;
  List<ScriptVariable> _variables = [];
  List<Server> _servers = [];
  bool _isLoading = false;

  // Variable editor controllers
  final _varNameController = TextEditingController();
  final _varDefaultController = TextEditingController();
  final _varDescController = TextEditingController();
  bool _varRequired = false;

  final List<String> _predefinedCategories = [
    'System',
    'Network',
    'Backup',
    'Monitoring',
    'Deployment',
    'Maintenance',
    'Security',
  ];

  @override
  void initState() {
    super.initState();
    _loadServers();

    if (widget.script != null) {
      _nameController.text = widget.script!.name;
      _categoryController.text = widget.script!.category ?? '';
      _contentController.text = widget.script!.content;
      _isReusable = widget.script!.isReusable;
      _selectedServerId = widget.script!.defaultServerId;
      _variables = List.from(widget.script!.variables);
    } else if (widget.initialIsReusable != null) {
      _isReusable = widget.initialIsReusable!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _contentController.dispose();
    _varNameController.dispose();
    _varDefaultController.dispose();
    _varDescController.dispose();
    super.dispose();
  }

  Future<void> _loadServers() async {
    final servers = await ServerRepository.getAll();
    setState(() {
      _servers = servers;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final surface = colors?.surface ?? CyberTermColors.surface;
    final primary = colors?.primary ?? CyberTermColors.primary;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final border = colors?.border ?? CyberTermColors.border;

    final isEditing = widget.script != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? '[EDIT SCRIPT]' : '[NEW SCRIPT]',
          style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Info Section
            _buildSectionHeader(context, 'BASIC INFO', colors),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Script Name',
                hintText: 'e.g., Update System Packages',
                prefixIcon: Icon(Icons.label),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
              style: GoogleFonts.jetBrainsMono(),
            ),
            const SizedBox(height: 16),

            // Category dropdown with custom option
            DropdownButtonFormField<String>(
              value: _predefinedCategories.contains(_categoryController.text)
                  ? _categoryController.text
                  : 'Custom',
              decoration: const InputDecoration(
                labelText: 'Category',
                prefixIcon: Icon(Icons.folder),
              ),
              items: [
                ..._predefinedCategories.map(
                  (cat) => DropdownMenuItem(
                    value: cat,
                    child: Text(cat, style: GoogleFonts.jetBrainsMono()),
                  ),
                ),
                DropdownMenuItem(
                  value: 'Custom',
                  child: Text('Custom...', style: GoogleFonts.jetBrainsMono()),
                ),
              ],
              onChanged: (value) {
                if (value != null && value != 'Custom') {
                  setState(() {
                    _categoryController.text = value;
                  });
                }
              },
              style: GoogleFonts.jetBrainsMono(),
              dropdownColor: surface,
            ),

            if (_categoryController.text.isEmpty ||
                !_predefinedCategories.contains(_categoryController.text))
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: TextFormField(
                  controller: _categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Custom Category',
                    prefixIcon: Icon(Icons.edit),
                  ),
                  style: GoogleFonts.jetBrainsMono(),
                ),
              ),

            const SizedBox(height: 24),

            // Script Type Section
            _buildSectionHeader(context, 'SCRIPT TYPE', colors),
            const SizedBox(height: 12),

            // Reusable toggle
            SwitchListTile(
              title: Text(
                'Reusable Script',
                style: GoogleFonts.jetBrainsMono(
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              subtitle: Text(
                'Can be run on any server',
                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: textDim),
              ),
              value: _isReusable,
              onChanged: (value) {
                setState(() {
                  _isReusable = value;
                  if (_isReusable) {
                    _selectedServerId = null;
                  }
                });
              },
              activeColor: primary,
              tileColor: surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide(color: border),
              ),
            ),

            if (!_isReusable) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                value: _selectedServerId,
                decoration: const InputDecoration(
                  labelText: 'Associated Server',
                  prefixIcon: Icon(Icons.computer),
                ),
                items: _servers.map((server) {
                  return DropdownMenuItem(
                    value: server.id,
                    child: Text(
                      server.name,
                      style: GoogleFonts.jetBrainsMono(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedServerId = value;
                  });
                },
                validator: (value) {
                  if (!_isReusable && value == null) {
                    return 'Please select a server';
                  }
                  return null;
                },
                style: GoogleFonts.jetBrainsMono(),
                dropdownColor: surface,
              ),
            ],

            const SizedBox(height: 24),

            // Script Content Section
            _buildSectionHeader(context, 'SCRIPT CONTENT', colors),
            const SizedBox(height: 12),

            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Script Content',
                hintText: '#!/bin/bash\necho "Hello, World!"',
                alignLabelWithHint: true,
              ),
              maxLines: 12,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Script content is required';
                }
                return null;
              },
              style: GoogleFonts.jetBrainsMono(fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Use \${VARIABLE_NAME} or \$VARIABLE_NAME for variable substitution',
              style: GoogleFonts.jetBrainsMono(fontSize: 10, color: textMuted),
            ),

            const SizedBox(height: 24),

            // Variables Section
            _buildSectionHeader(context, 'VARIABLES', colors),
            const SizedBox(height: 12),

            if (_variables.isNotEmpty) ...[
              ..._variables.asMap().entries.map((entry) {
                final index = entry.key;
                final variable = entry.value;
                return _buildVariableCard(index, variable, colors);
              }),
              const SizedBox(height: 16),
            ],

            // Add Variable Form
            _buildAddVariableForm(colors),

            const SizedBox(height: 32),

            // Save Button
            FilledButton.icon(
              onPressed: _isLoading ? null : _saveScript,
              icon: _isLoading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colors?.background ?? CyberTermColors.background,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(
                isEditing ? '[SAVE CHANGES]' : '[CREATE SCRIPT]',
                style: GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    CyberTermThemeExtension? colors,
  ) {
    final primary = colors?.primary ?? CyberTermColors.primary;

    return Row(
      children: [
        const TerminalLabel('SECTION'),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.jetBrainsMono(
            color: primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildVariableCard(
    int index,
    ScriptVariable variable,
    CyberTermThemeExtension? colors,
  ) {
    final surfaceLight = colors?.surfaceLight ?? CyberTermColors.surfaceLight;
    final primary = colors?.primary ?? CyberTermColors.primary;
    final textDim = colors?.textDim ?? CyberTermColors.textDim;
    final textMuted = colors?.textMuted ?? CyberTermColors.textMuted;
    final warning = colors?.warning ?? CyberTermColors.warning;
    final error = colors?.error ?? CyberTermColors.error;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: surfaceLight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '\${${variable.name}}',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                      if (variable.required) ...[
                        const SizedBox(width: 8),
                        Text(
                          '[REQUIRED]',
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 9,
                            color: warning,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete, size: 18, color: error),
                  onPressed: () {
                    setState(() {
                      _variables.removeAt(index);
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            if (variable.defaultValue != null) ...[
              const SizedBox(height: 4),
              Text(
                'Default: ${variable.defaultValue}',
                style: GoogleFonts.jetBrainsMono(fontSize: 11, color: textDim),
              ),
            ],
            if (variable.description != null) ...[
              const SizedBox(height: 4),
              Text(
                variable.description!,
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: textMuted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddVariableForm(CyberTermThemeExtension? colors) {
    final background = colors?.background ?? CyberTermColors.background;
    final border = colors?.border ?? CyberTermColors.border;
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final primary = colors?.primary ?? CyberTermColors.primary;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '[ADD VARIABLE]',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: primaryDim,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _varNameController,
            decoration: const InputDecoration(
              labelText: 'Variable Name',
              hintText: 'e.g., DOMAIN',
            ),
            style: GoogleFonts.jetBrainsMono(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _varDefaultController,
            decoration: const InputDecoration(
              labelText: 'Default Value (optional)',
              hintText: 'e.g., example.com',
            ),
            style: GoogleFonts.jetBrainsMono(),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _varDescController,
            decoration: const InputDecoration(
              labelText: 'Description (optional)',
              hintText: 'e.g., The domain name to configure',
            ),
            style: GoogleFonts.jetBrainsMono(),
          ),
          const SizedBox(height: 12),
          CheckboxListTile(
            title: Text(
              'Required',
              style: GoogleFonts.jetBrainsMono(fontSize: 12, color: textColor),
            ),
            value: _varRequired,
            onChanged: (value) {
              setState(() {
                _varRequired = value ?? false;
              });
            },
            activeColor: primary,
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _addVariable,
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              '[ADD VARIABLE]',
              style: GoogleFonts.jetBrainsMono(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 36),
            ),
          ),
        ],
      ),
    );
  }

  void _addVariable() {
    final name = _varNameController.text.trim();
    if (name.isEmpty) {
      final theme = Theme.of(context);
      final colors = theme.extension<CyberTermThemeExtension>();
      final surface = colors?.surface ?? CyberTermColors.surface;
      final error = colors?.error ?? CyberTermColors.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Variable name is required',
            style: GoogleFonts.jetBrainsMono(color: error),
          ),
          backgroundColor: surface,
        ),
      );
      return;
    }

    // Check for duplicates
    if (_variables.any((v) => v.name == name)) {
      final theme = Theme.of(context);
      final colors = theme.extension<CyberTermThemeExtension>();
      final surface = colors?.surface ?? CyberTermColors.surface;
      final error = colors?.error ?? CyberTermColors.error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Variable \$name already exists',
            style: GoogleFonts.jetBrainsMono(color: error),
          ),
          backgroundColor: surface,
        ),
      );
      return;
    }

    setState(() {
      _variables.add(
        ScriptVariable(
          name: name,
          defaultValue: _varDefaultController.text.trim().isEmpty
              ? null
              : _varDefaultController.text.trim(),
          required: _varRequired,
          description: _varDescController.text.trim().isEmpty
              ? null
              : _varDescController.text.trim(),
        ),
      );

      // Clear controllers
      _varNameController.clear();
      _varDefaultController.clear();
      _varDescController.clear();
      _varRequired = false;
    });
  }

  Future<void> _saveScript() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final isEditing = widget.script != null;
    final notifier = ref.read(scriptsProvider.notifier);

    final script = Script(
      id: widget.script?.id,
      name: _nameController.text.trim(),
      content: _contentController.text,
      isReusable: _isReusable,
      defaultServerId: _isReusable ? null : _selectedServerId,
      category: _categoryController.text.trim().isEmpty
          ? null
          : _categoryController.text.trim(),
      variables: _variables,
    );

    try {
      if (isEditing) {
        await notifier.updateScript(script);
      } else {
        await notifier.addScript(script);
      }

      if (mounted) {
        Navigator.pop(context, script);
      }
    } catch (e) {
      if (mounted) {
        final theme = Theme.of(context);
        final colors = theme.extension<CyberTermThemeExtension>();
        final surface = colors?.surface ?? CyberTermColors.surface;
        final error = colors?.error ?? CyberTermColors.error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: $e',
              style: GoogleFonts.jetBrainsMono(color: error),
            ),
            backgroundColor: surface,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
