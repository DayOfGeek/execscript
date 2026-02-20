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

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

/// Service for securely storing and retrieving credentials
class CredentialService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  /// Store a credential for a server
  static Future<void> storeCredential(
    String serverKey,
    String credential,
  ) async {
    final key = '${AppConstants.credentialKeyPrefix}$serverKey';
    await _storage.write(key: key, value: credential);
  }

  /// Retrieve a credential for a server
  static Future<String?> getCredential(String serverKey) async {
    final key = '${AppConstants.credentialKeyPrefix}$serverKey';
    return await _storage.read(key: key);
  }

  /// Delete a credential for a server
  static Future<void> deleteCredential(String serverKey) async {
    final key = '${AppConstants.credentialKeyPrefix}$serverKey';
    await _storage.delete(key: key);
  }

  /// Delete all credentials (use with caution)
  static Future<void> deleteAllCredentials() async {
    await _storage.deleteAll();
  }

  /// Generate a unique credential key for a server
  static String generateCredentialKey(int? serverId) {
    if (serverId != null) {
      return 'server_$serverId';
    }
    // For new servers, use timestamp
    return 'new_${DateTime.now().millisecondsSinceEpoch}';
  }
}
