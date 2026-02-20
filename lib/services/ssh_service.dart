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

import 'dart:async';
import 'dart:typed_data';
import 'package:dartssh2/dartssh2.dart';
import '../data/models/server.dart';
import '../services/credential_service.dart';

/// Exception thrown when host key verification fails
class HostKeyVerificationException implements Exception {
  final String expected;
  final String received;
  final String message;

  HostKeyVerificationException({required this.expected, required this.received})
    : message =
          'HOST KEY VERIFICATION FAILED!\n'
          'Expected: $expected\n'
          'Got: $received\n'
          'Possible MITM attack or server key changed.';

  @override
  String toString() => message;
}

/// Exception thrown when a new host key is encountered
class NewHostKeyException implements Exception {
  final String fingerprint;
  final String serverName;
  final String hostKeyType;

  NewHostKeyException({
    required this.fingerprint,
    required this.serverName,
    required this.hostKeyType,
  });

  @override
  String toString() =>
      'New host key for $serverName ($hostKeyType): $fingerprint';
}

/// Output from SSH command
class SSHOutput {
  final String content;
  final bool isError;
  final DateTime timestamp;

  SSHOutput({required this.content, this.isError = false, DateTime? timestamp})
    : timestamp = timestamp ?? DateTime.now();
}

/// Result of SSH command execution
class SSHResult {
  final String stdout;
  final String stderr;
  final int exitCode;
  final Duration duration;

  SSHResult({
    required this.stdout,
    required this.stderr,
    required this.exitCode,
    required this.duration,
  });
}

/// SSH session wrapper
class SSHSession {
  final SSHClient client;
  final Server server;
  final DateTime connectedAt;

  SSHSession({
    required this.client,
    required this.server,
    DateTime? connectedAt,
  }) : connectedAt = connectedAt ?? DateTime.now();

  bool get isConnected => client.isClosed == false;

  Future<void> close() async {
    client.close();
  }
}

/// Converts a fingerprint Uint8List to MD5 hex string format
/// e.g., "00:11:22:33:44:55:66:77:88:99:aa:bb:cc:dd:ee:ff"
String _formatFingerprint(Uint8List fingerprint) {
  return fingerprint.map((b) => b.toRadixString(16).padLeft(2, '0')).join(':');
}

/// Service for SSH operations
class SSHService {
  /// Connect to a server with host key verification
  ///
  /// On first connection, the server's host key fingerprint is captured
  /// and can be stored for future verification.
  /// On subsequent connections, the fingerprint must match the stored value.
  static Future<SSHSession> connect(
    Server server, {
    bool acceptNewHostKey = false,
  }) async {
    // Get credentials from secure storage
    final credential = await CredentialService.getCredential(
      server.credentialKey,
    );
    if (credential == null) {
      throw Exception('Credentials not found for server ${server.name}');
    }

    // Variables to capture host key info from verification callback
    String? capturedFingerprint;
    String? capturedKeyType;
    bool? hostKeyAccepted;

    // Create socket
    final socket = await SSHSocket.connect(
      server.hostname,
      server.port,
      timeout: const Duration(seconds: 20),
    );

    SSHClient? client;
    try {
      // Create client with host key verification callback
      if (server.authType == AuthType.password) {
        client = SSHClient(
          socket,
          username: server.username,
          onPasswordRequest: () => credential,
          onVerifyHostKey: (type, fingerprint) {
            capturedKeyType = type;
            capturedFingerprint = _formatFingerprint(fingerprint);

            // Check if we have a stored fingerprint
            if (server.keyFingerprint != null &&
                server.keyFingerprint!.isNotEmpty) {
              if (capturedFingerprint == server.keyFingerprint) {
                hostKeyAccepted = true;
                return true; // Accept matching key
              } else {
                hostKeyAccepted = false;
                return false; // Reject - mismatch (potential MITM)
              }
            } else {
              // No stored fingerprint - this is a first-time connection
              if (acceptNewHostKey) {
                hostKeyAccepted = true;
                return true; // Accept new key
              } else {
                hostKeyAccepted = false;
                return false; // Reject - need user confirmation
              }
            }
          },
        );
      } else {
        // Key-based authentication
        try {
          // Parse private key from PEM format
          final identities = SSHKeyPair.fromPem(credential);
          client = SSHClient(
            socket,
            username: server.username,
            identities: identities,
            onVerifyHostKey: (type, fingerprint) {
              capturedKeyType = type;
              capturedFingerprint = _formatFingerprint(fingerprint);

              // Check if we have a stored fingerprint
              if (server.keyFingerprint != null &&
                  server.keyFingerprint!.isNotEmpty) {
                if (capturedFingerprint == server.keyFingerprint) {
                  hostKeyAccepted = true;
                  return true; // Accept matching key
                } else {
                  hostKeyAccepted = false;
                  return false; // Reject - mismatch (potential MITM)
                }
              } else {
                // No stored fingerprint - this is a first-time connection
                if (acceptNewHostKey) {
                  hostKeyAccepted = true;
                  return true; // Accept new key
                } else {
                  hostKeyAccepted = false;
                  return false; // Reject - need user confirmation
                }
              }
            },
          );
        } catch (e) {
          socket.destroy();
          throw Exception('Invalid private key: $e');
        }
      }

      // Wait for authentication
      try {
        await client.authenticated;
      } catch (e) {
        // Check if the error was due to host key verification
        if (hostKeyAccepted == false) {
          client.close();
          if (server.keyFingerprint != null &&
              server.keyFingerprint!.isNotEmpty) {
            // We had a stored fingerprint but it didn't match
            throw HostKeyVerificationException(
              expected: server.keyFingerprint!,
              received: capturedFingerprint ?? 'unknown',
            );
          } else {
            // No stored fingerprint - this is a new host
            throw NewHostKeyException(
              fingerprint: capturedFingerprint ?? 'unknown',
              serverName: server.name,
              hostKeyType: capturedKeyType ?? 'unknown',
            );
          }
        }
        rethrow;
      }

      return SSHSession(client: client, server: server);
    } catch (e) {
      // Ensure client is closed on any error
      client?.close();
      rethrow;
    }
  }

  /// Connect to a server and automatically store the host key fingerprint
  ///
  /// This is a convenience method for the initial server setup flow.
  /// It returns both the session and the captured fingerprint.
  static Future<(SSHSession, String?)> connectAndCaptureFingerprint(
    Server server,
  ) async {
    // Get credentials from secure storage
    final credential = await CredentialService.getCredential(
      server.credentialKey,
    );
    if (credential == null) {
      throw Exception('Credentials not found for server ${server.name}');
    }

    // Variables to capture host key info from verification callback
    String? capturedFingerprint;

    // Create socket
    final socket = await SSHSocket.connect(
      server.hostname,
      server.port,
      timeout: const Duration(seconds: 20),
    );

    SSHClient? client;
    try {
      // Create client with host key verification callback
      if (server.authType == AuthType.password) {
        client = SSHClient(
          socket,
          username: server.username,
          onPasswordRequest: () => credential,
          onVerifyHostKey: (type, fingerprint) {
            capturedFingerprint = _formatFingerprint(fingerprint);

            // Verify host key if we have a stored fingerprint
            if (server.keyFingerprint != null &&
                server.keyFingerprint!.isNotEmpty) {
              if (capturedFingerprint == server.keyFingerprint) {
                return true; // Accept matching key
              } else {
                return false; // Reject - mismatch (potential MITM)
              }
            }
            // No stored fingerprint - accept this new key
            return true;
          },
        );
      } else {
        // Key-based authentication
        try {
          // Parse private key from PEM format
          final identities = SSHKeyPair.fromPem(credential);
          client = SSHClient(
            socket,
            username: server.username,
            identities: identities,
            onVerifyHostKey: (type, fingerprint) {
              capturedFingerprint = _formatFingerprint(fingerprint);

              // Verify host key if we have a stored fingerprint
              if (server.keyFingerprint != null &&
                  server.keyFingerprint!.isNotEmpty) {
                if (capturedFingerprint == server.keyFingerprint) {
                  return true; // Accept matching key
                } else {
                  return false; // Reject - mismatch (potential MITM)
                }
              }
              // No stored fingerprint - accept this new key
              return true;
            },
          );
        } catch (e) {
          socket.destroy();
          throw Exception('Invalid private key: $e');
        }
      }

      // Wait for authentication
      try {
        await client.authenticated;
      } catch (e) {
        // Check if the error was due to host key verification
        if (server.keyFingerprint != null &&
            server.keyFingerprint!.isNotEmpty) {
          client.close();
          throw HostKeyVerificationException(
            expected: server.keyFingerprint!,
            received: capturedFingerprint ?? 'unknown',
          );
        }
        rethrow;
      }

      if (capturedFingerprint == null) {
        client.close();
        throw Exception('Failed to capture host key fingerprint');
      }

      final session = SSHSession(client: client, server: server);
      return (session, capturedFingerprint);
    } catch (e) {
      client?.close();
      rethrow;
    }
  }

  /// Execute a command and stream output
  static Stream<SSHOutput> executeStream(
    SSHSession session,
    String command, {
    Duration timeout = const Duration(minutes: 5),
  }) async* {
    final stopwatch = Stopwatch()..start();
    final session2 = await session.client.execute(command);

    // Merge stdout and stderr streams
    await for (final data in session2.stdout) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'Command timed out after ${timeout.inMinutes} minutes',
        );
      }
      yield SSHOutput(content: String.fromCharCodes(data), isError: false);
    }

    await for (final data in session2.stderr) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'Command timed out after ${timeout.inMinutes} minutes',
        );
      }
      yield SSHOutput(content: String.fromCharCodes(data), isError: true);
    }

    await session2.done;
  }

  /// Execute a command and return result
  static Future<SSHResult> execute(
    SSHSession session,
    String command, {
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final stopwatch = Stopwatch()..start();
    final stdout = StringBuffer();
    final stderr = StringBuffer();

    final session2 = await session.client.execute(command);

    // Read stdout
    await for (final data in session2.stdout) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'Command timed out after ${timeout.inMinutes} minutes',
        );
      }
      stdout.write(String.fromCharCodes(data));
    }

    // Read stderr
    await for (final data in session2.stderr) {
      if (stopwatch.elapsed > timeout) {
        throw TimeoutException(
          'Command timed out after ${timeout.inMinutes} minutes',
        );
      }
      stderr.write(String.fromCharCodes(data));
    }

    await session2.done;
    stopwatch.stop();

    return SSHResult(
      stdout: stdout.toString(),
      stderr: stderr.toString(),
      exitCode: session2.exitCode ?? -1,
      duration: stopwatch.elapsed,
    );
  }

  /// Test connection to server
  static Future<bool> testConnection(Server server) async {
    try {
      final session = await connect(server, acceptNewHostKey: true);
      await session.close();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Test connection and return fingerprint info
  /// Returns (success, fingerprint, isNewKey, errorMessage)
  static Future<(bool, String?, bool, String?)> testConnectionWithFingerprint(
    Server server,
  ) async {
    try {
      final (session, fingerprint) = await connectAndCaptureFingerprint(server);
      await session.close();
      final isNew =
          server.keyFingerprint == null ||
          server.keyFingerprint!.isEmpty ||
          server.keyFingerprint != fingerprint;
      return (true, fingerprint, isNew, null);
    } on HostKeyVerificationException catch (e) {
      return (false, e.received, false, e.message);
    } on NewHostKeyException catch (e) {
      return (false, e.fingerprint, true, e.toString());
    } catch (e) {
      return (false, null, false, e.toString());
    }
  }

  /// Disconnect session
  static Future<void> disconnect(SSHSession session) async {
    await session.close();
  }
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
