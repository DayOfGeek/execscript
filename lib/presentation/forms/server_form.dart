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
import '../../data/models/server.dart';
import '../../services/credential_service.dart';
import '../../services/ssh_service.dart';
import '../providers/servers_provider.dart';
import '../widgets/host_key_dialog.dart';

/// Form for adding or editing a server
class ServerForm extends ConsumerStatefulWidget {
  final Server? server; // null for new server

  const ServerForm({super.key, this.server});

  @override
  ConsumerState<ServerForm> createState() => _ServerFormState();
}

class _ServerFormState extends ConsumerState<ServerForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _hostnameController = TextEditingController();
  final _portController = TextEditingController(text: '22');
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sshKeyController = TextEditingController();
  final _tagsController = TextEditingController();

  AuthType _authType = AuthType.password;
  PreferredShell _preferredShell = PreferredShell.tmux;
  bool _isTesting = false;
  String? _testError;
  String? _capturedFingerprint;

  @override
  void initState() {
    super.initState();
    if (widget.server != null) {
      _nameController.text = widget.server!.name;
      _hostnameController.text = widget.server!.hostname;
      _portController.text = widget.server!.port.toString();
      _usernameController.text = widget.server!.username;
      _authType = widget.server!.authType;
      _preferredShell = widget.server!.preferredShell;
      _tagsController.text = widget.server!.tags.join(', ');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostnameController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _sshKeyController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.extension<CyberTermThemeExtension>();
    final surface = colors?.surface ?? CyberTermColors.surface;
    final primary = colors?.primary ?? CyberTermColors.primary;
    final primaryDim = colors?.primaryDim ?? CyberTermColors.primaryDim;
    final textColor = colors?.textColor ?? CyberTermColors.textColor;
    final error = colors?.error ?? CyberTermColors.error;
    final success = colors?.success ?? CyberTermColors.success;

    final isEditing = widget.server != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? '[EDIT SERVER]' : '[NEW SERVER]',
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
                labelText: 'Server Name',
                hintText: 'e.g., Production Web Server',
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

            TextFormField(
              controller: _hostnameController,
              decoration: const InputDecoration(
                labelText: 'Hostname or IP',
                hintText: 'e.g., 192.168.1.100 or server.example.com',
                prefixIcon: Icon(Icons.computer),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Hostname is required';
                }
                return null;
              },
              style: GoogleFonts.jetBrainsMono(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'e.g., root',
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Username is required';
                      }
                      return null;
                    },
                    style: GoogleFonts.jetBrainsMono(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _portController,
                    decoration: const InputDecoration(
                      labelText: 'Port',
                      prefixIcon: Icon(Icons.settings_ethernet),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Port required';
                      }
                      final port = int.tryParse(value);
                      if (port == null || port < 1 || port > 65535) {
                        return 'Invalid port';
                      }
                      return null;
                    },
                    style: GoogleFonts.jetBrainsMono(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Authentication Section
            _buildSectionHeader(context, 'AUTHENTICATION', colors),
            const SizedBox(height: 12),

            // Auth type toggle
            SegmentedButton<AuthType>(
              segments: const [
                ButtonSegment(
                  value: AuthType.password,
                  label: Text('PASSWORD'),
                  icon: Icon(Icons.password),
                ),
                ButtonSegment(
                  value: AuthType.key,
                  label: Text('SSH KEY'),
                  icon: Icon(Icons.vpn_key),
                ),
              ],
              selected: {_authType},
              onSelectionChanged: (Set<AuthType> selection) {
                setState(() {
                  _authType = selection.first;
                });
              },
              style: SegmentedButton.styleFrom(
                backgroundColor: surface,
                selectedBackgroundColor: primaryDim,
                foregroundColor: textColor,
                selectedForegroundColor: textColor,
              ),
            ),
            const SizedBox(height: 16),

            // Password or SSH Key field
            if (_authType == AuthType.password)
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter SSH password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (!isEditing && (value == null || value.isEmpty)) {
                    return 'Password is required';
                  }
                  return null;
                },
                style: GoogleFonts.jetBrainsMono(),
              )
            else
              TextFormField(
                controller: _sshKeyController,
                decoration: const InputDecoration(
                  labelText: 'SSH Private Key',
                  hintText: 'Paste your private key here (PEM format)',
                  prefixIcon: Icon(Icons.vpn_key),
                  alignLabelWithHint: true,
                ),
                maxLines: 8,
                validator: (value) {
                  if (!isEditing && (value == null || value.isEmpty)) {
                    return 'SSH key is required';
                  }
                  return null;
                },
                style: GoogleFonts.jetBrainsMono(fontSize: 11),
              ),
            const SizedBox(height: 24),

            // Options Section
            _buildSectionHeader(context, 'OPTIONS', colors),
            const SizedBox(height: 12),

            // Preferred shell dropdown
            DropdownButtonFormField<PreferredShell>(
              value: _preferredShell,
              decoration: const InputDecoration(
                labelText: 'Preferred Shell for Background Jobs',
                prefixIcon: Icon(Icons.terminal),
              ),
              items: PreferredShell.values.map((shell) {
                return DropdownMenuItem(
                  value: shell,
                  child: Text(
                    shell.name.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _preferredShell = value;
                  });
                }
              },
              style: GoogleFonts.jetBrainsMono(),
              dropdownColor: surface,
            ),
            const SizedBox(height: 16),

            // Tags input
            TextFormField(
              controller: _tagsController,
              decoration: const InputDecoration(
                labelText: 'Tags (comma-separated)',
                hintText: 'e.g., production, web, ubuntu',
                prefixIcon: Icon(Icons.local_offer),
              ),
              style: GoogleFonts.jetBrainsMono(),
            ),
            const SizedBox(height: 24),

            // Test Connection Status
            if (_testError != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border.all(color: error),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: error, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testError!,
                        style: GoogleFonts.jetBrainsMono(
                          color: error,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (_capturedFingerprint != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: surface,
                  border: Border.all(color: success),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: success, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '[HOST KEY VERIFIED]',
                          style: GoogleFonts.jetBrainsMono(
                            color: success,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Fingerprint: $_capturedFingerprint',
                      style: GoogleFonts.jetBrainsMono(
                        color: colors?.textDim ?? CyberTermColors.textDim,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isTesting ? null : _testConnection,
                    icon: _isTesting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: primary,
                            ),
                          )
                        : const Icon(Icons.network_check),
                    label: Text(
                      _isTesting ? '[TESTING...]' : '[TEST CONNECTION]',
                      style: GoogleFonts.jetBrainsMono(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: FilledButton.icon(
                    onPressed: _saveServer,
                    icon: const Icon(Icons.save),
                    label: Text(
                      isEditing ? '[SAVE CHANGES]' : '[ADD SERVER]',
                      style: GoogleFonts.jetBrainsMono(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
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

  Future<void> _testConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isTesting = true;
      _testError = null;
      _capturedFingerprint = null;
    });

    try {
      // Get credential from form
      final credential = _authType == AuthType.password
          ? _passwordController.text
          : _sshKeyController.text;

      if (credential.isEmpty) {
        setState(() {
          _testError = 'Please enter a password or SSH key';
        });
        return;
      }

      // Temporarily store credential for testing
      final tempKey = 'temp_test_${DateTime.now().millisecondsSinceEpoch}';
      await CredentialService.storeCredential(tempKey, credential);

      // Create a temporary server object for testing
      final testServer = Server(
        id: widget.server?.id,
        name: _nameController.text,
        hostname: _hostnameController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        authType: _authType,
        credentialKey: tempKey,
        keyFingerprint: widget.server?.keyFingerprint,
        preferredShell: _preferredShell,
        tags: _tagsController.text
            .split(',')
            .map((t) => t.trim())
            .where((t) => t.isNotEmpty)
            .toList(),
      );

      // Test with fingerprint capture
      final (success, fingerprint, isNewKey, errorMessage) =
          await SSHService.testConnectionWithFingerprint(testServer);

      // Clean up temp credential
      await CredentialService.deleteCredential(tempKey);

      if (success) {
        setState(() {
          _capturedFingerprint = fingerprint;
          _testError = null;
        });

        // If this is a new key, show dialog to trust
        if (isNewKey && fingerprint != null && mounted) {
          final trustResult = await showDialog<HostKeyTrust>(
            context: context,
            builder: (context) => HostKeyDialog(
              fingerprint: fingerprint,
              serverName: testServer.name,
              isNewKey: true,
            ),
          );

          if (trustResult == HostKeyTrust.always) {
            // Save fingerprint to server
            setState(() {
              _capturedFingerprint = fingerprint;
            });
          } else if (trustResult == null || trustResult == HostKeyTrust.never) {
            setState(() {
              _capturedFingerprint = null;
              _testError = 'Connection cancelled - host key not trusted';
            });
          }
        }
      } else {
        // Check if this is a changed key
        if (!isNewKey && fingerprint != null && mounted) {
          final trustResult = await showDialog<HostKeyTrust>(
            context: context,
            builder: (context) => HostKeyDialog(
              fingerprint: fingerprint,
              serverName: testServer.name,
              isNewKey: false,
              expectedFingerprint: widget.server?.keyFingerprint,
            ),
          );

          if (trustResult == HostKeyTrust.always) {
            setState(() {
              _capturedFingerprint = fingerprint;
            });
          } else {
            setState(() {
              _testError = errorMessage ?? 'Host key verification failed';
            });
          }
        } else {
          setState(() {
            _testError = errorMessage ?? 'Connection failed';
          });
        }
      }
    } catch (e) {
      setState(() {
        _testError = 'Connection error: $e';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final isEditing = widget.server != null;
    final notifier = ref.read(serversProvider.notifier);

    final server = Server(
      id: widget.server?.id,
      name: _nameController.text,
      hostname: _hostnameController.text,
      port: int.parse(_portController.text),
      username: _usernameController.text,
      authType: _authType,
      credentialKey: widget.server?.credentialKey ?? '',
      keyFingerprint: _capturedFingerprint ?? widget.server?.keyFingerprint,
      preferredShell: _preferredShell,
      tags: _tagsController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList(),
    );

    try {
      late final Server savedServer;
      if (isEditing) {
        await notifier.updateServer(server);
        savedServer = server;
      } else {
        savedServer = await notifier.addServer(server);
      }

      // Store credentials
      final credential = _authType == AuthType.password
          ? _passwordController.text
          : _sshKeyController.text;

      if (credential.isNotEmpty) {
        await CredentialService.storeCredential(
          savedServer.credentialKey,
          credential,
        );
      }

      if (mounted) {
        Navigator.pop(context, savedServer);
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
    }
  }
}
