# ExecScript Security Review - Foundation

**Date:** 2026-02-19  
**Reviewer:** Security Engineer  
**Scope:** Core security files in lib/services/, lib/data/  
**Application:** ExecScript Flutter Mobile App

---

## 1. Executive Summary

**Overall Security Posture: 🔴 AT RISK**

The ExecScript application has a solid foundation with proper credential storage using device secure storage (iOS Keychain/Android Keystore). However, there are **CRITICAL** security vulnerabilities that must be addressed before production release, primarily around **host key verification** (missing MITM protection) and **command injection** vulnerabilities in script execution.

### Key Concerns Summary:
| Category | Status | Priority |
|----------|--------|----------|
| Credential Storage | ✅ Properly implemented | - |
| Memory Safety | ⚠️ Needs improvement | HIGH |
| Host Key Verification | 🔴 Missing | CRITICAL |
| Command Injection | 🔴 Vulnerable | CRITICAL |
| SQL Injection | ✅ Protected | - |
| Error Handling | ⚠️ Partial | MEDIUM |

---

## 2. Critical Findings

### 🔴 CRITICAL-001: Missing SSH Host Key Verification (MITM Vulnerability)

**Location:** `lib/services/ssh_service.dart:66-98`

**Issue:** The SSH connection does not implement host key verification. When connecting to a server, the application does not verify the server's identity using its SSH host key fingerprint. This leaves the app vulnerable to Man-in-the-Middle (MITM) attacks where an attacker can impersonate the target server.

**Current Code:**
```dart
final socket = await SSHSocket.connect(
  server.hostname,
  server.port,
  timeout: const Duration(seconds: 20),
);
// No host key verification!
```

**Impact:** An attacker on the same network can intercept SSH connections and steal credentials or execute malicious commands on the server.

**Remediation:**
```dart
final socket = await SSHSocket.connect(
  server.hostname,
  server.port,
  timeout: const Duration(seconds: 20),
);

// Verify host key against stored fingerprint
final remoteFingerprint = await socket.peerFingerprint();
if (server.keyFingerprint != null) {
  if (remoteFingerprint != server.keyFingerprint) {
    socket.destroy();
    throw Exception(
      'HOST KEY VERIFICATION FAILED!\n'
      'Expected: ${server.keyFingerprint}\n'
      'Got: $remoteFingerprint\n'
      'Possible MITM attack or server key changed.'
    );
  }
} else {
  // First-time connection - store fingerprint and warn user
  await _promptUserToAcceptFingerprint(server, remoteFingerprint);
}
```

---

### 🔴 CRITICAL-002: Command Injection in Tmux/Script Execution

**Location:** Multiple files
- `lib/services/tmux_service.dart:41,57-58,77,161,179,212`
- `lib/services/script.dart:60-68` (variable injection)

**Issue:** User-provided input (session names, commands, script content) is directly interpolated into shell commands without proper sanitization or escaping, enabling command injection attacks.

**Vulnerable Code Example:**
```dart
// tmux_service.dart:57-58
final cmd = pressEnter
    ? 'tmux send-keys -t "$sessionName" "$command" Enter'
    : 'tmux send-keys -t "$sessionName" "$command"';
```

If `sessionName` contains `"; rm -rf /; echo "`, arbitrary commands can be executed.

**Impact:** Attackers can execute arbitrary commands on the server with the privileges of the SSH user, potentially leading to complete server compromise.

**Remediation:**
```dart
/// Sanitize input for shell commands using proper escaping
String sanitizeForShell(String input) {
  // Use single quotes and escape any single quotes within
  // This is the most reliable method for bash/sh
  return "'" + input.replaceAll("'", "'\\''") + "'";
}

// Use parameterized/sanitized input
final safeSessionName = sanitizeForShell(sessionName);
final safeCommand = sanitizeForShell(command);
final cmd = 'tmux send-keys -t $safeSessionName $safeCommand Enter';
```

For script variables injection (`script.dart:60-68`), also implement proper escaping:
```dart
String injectVariables(Map<String, String> values) {
  var result = content;
  for (final variable in variables) {
    final value = sanitizeForShell(
      values[variable.name] ?? variable.defaultValue ?? ''
    );
    // ... rest of replacement
  }
  return result;
}
```

---

### 🟠 HIGH-001: Credentials Persist in Memory

**Location:** `lib/services/ssh_service.dart:59-93`

**Issue:** SSH credentials (passwords and private keys) are retrieved from secure storage and held in memory as Dart strings for the duration of the connection. Dart strings are immutable and cannot be explicitly cleared from memory. Additionally, private keys are parsed and held in memory.

**Current Code:**
```dart
final credential = await CredentialService.getCredential(server.credentialKey);
// credential remains in memory until garbage collected
```

**Impact:** 
- Credentials may persist in memory longer than necessary
- Memory dumps or debugging tools could extract credentials
- Private keys are particularly sensitive

**Remediation:**
While Dart doesn't provide direct memory clearing, implement these mitigations:

1. **Minimize credential lifetime:**
```dart
static Future<SSHSession> connect(Server server) async {
  // Get credentials
  final credential = await CredentialService.getCredential(server.credentialKey);
  if (credential == null) throw Exception('Credentials not found');
  
  try {
    // Use credential immediately
    final client = await _authenticate(server, credential);
    // credential should go out of scope here
    return SSHSession(client: client, server: server);
  } finally {
    // Force null to help GC (limited effectiveness in Dart)
    credential = null;
  }
}
```

2. **For private keys, consider using dartssh2's direct key parsing without storing the PEM string:**
```dart
// Parse key and discard original PEM
final identities = SSHKeyPair.fromPem(credential);
credential = null; // Help GC
```

3. **Document this limitation** in security documentation.

---

### 🟠 HIGH-002: Session Name Predictability

**Location:** `lib/services/tmux_service.dart:8-10`

**Issue:** Tmux session names are generated predictably using execution ID:
```dart
static String generateSessionName(int executionId) {
  return '${AppConstants.tmuxSessionPrefix}-$executionId'; // "execscript-123"
}
```

**Impact:** If an attacker gains access to the server, they can predict and potentially hijack or interfere with other users' tmux sessions.

**Remediation:**
```dart
import 'dart:math';
import 'dart:convert';

static String generateSessionName(int executionId) {
  // Add random component to prevent prediction
  final random = Random.secure().nextInt(10000).toString().padLeft(4, '0');
  final hash = base64Url.encode(
    sha256.convert(utf8.encode('$executionId-$random-${DateTime.now()}')).bytes
  ).substring(0, 8);
  return '${AppConstants.tmuxSessionPrefix}-$executionId-$hash';
}
```

---

## 3. Medium Findings

### 🟡 MEDIUM-001: Sensitive Data in Error Messages

**Location:** `lib/services/ssh_service.dart:62,91,185`

**Issue:** Error messages may leak sensitive information. For example:
```dart
throw Exception('Credentials not found for server ${server.name}');
throw Exception('Invalid private key: $e');
```

While not critical here, if exception messages are displayed to users or logged, they could reveal internal details.

**Remediation:**
```dart
// Log full details internally (if logging is implemented)
logger.error('SSH connection failed', error: e, server: server.hostname);

// Show generic message to user
throw Exception('Failed to connect to server. Please check your credentials.');
```

---

### 🟡 MEDIUM-002: Screen Command Injection (Less Severe)

**Location:** `lib/services/tmux_service.dart:179`

**Issue:** Similar to CRITICAL-002, screen commands are vulnerable:
```dart
final result = await SSHService.execute(session, '$cmd$enterCmd');
```

**Remediation:** Apply same sanitization as tmux commands.

---

### 🟡 MEDIUM-003: Execution Output Stored Unencrypted

**Location:** `lib/data/models/execution.dart:15,87`, `lib/data/repositories/execution_repository.dart`

**Issue:** Script execution output is stored in SQLite without encryption. This output may contain sensitive information (configuration data, environment variables, etc.).

**Remediation:** Consider encrypting sensitive execution output fields using the same secure storage mechanism or AES encryption with a key stored in secure storage.

---

### 🟡 MEDIUM-004: Weak Exit Code Detection

**Location:** `lib/services/execution_service.dart:64`

**Issue:** Exit code is guessed based on output text rather than actual exit code:
```dart
final exitCode = fullOutput.toLowerCase().contains('error') ? 1 : 0;
```

This is unreliable and could mark failed executions as successful.

**Remediation:** Capture actual exit code from SSH session:
```dart
await session2.done;
final actualExitCode = session2.exitCode ?? -1;
```

---

### 🟢 LOW-001: Unencrypted Database

**Location:** `lib/data/database.dart`

**Issue:** The SQLite database stores server information (hostnames, usernames) in plain text on the device.

**Impact:** Low - Server metadata is less sensitive than credentials, but could reveal infrastructure information if device is compromised.

**Remediation:** Consider using `sqflite_sqlcipher` for encrypted database storage.

---

### 🟢 LOW-002: Variable Storage Format

**Location:** `lib/data/models/execution.dart:87`

**Issue:** Variables are stored using `.toString()` on a Map, which is not a proper serialization format:
```dart
'variables_used': variablesUsed.toString(),
```

**Remediation:** Use JSON encoding:
```dart
import 'dart:convert';
'variables_used': jsonEncode(variablesUsed),
```

---

## 4. Positive Security Measures

The following security measures are correctly implemented:

### ✅ SECURE-001: Proper Credential Storage

**Location:** `lib/services/credential_service.dart`

The application correctly uses `flutter_secure_storage` which delegates to:
- **iOS:** Keychain with `KeychainAccessibility.first_unlock` (credentials not available until first device unlock)
- **Android:** Encrypted SharedPreferences

```dart
static const _storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    encryptedSharedPreferences: true,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
  ),
);
```

### ✅ SECURE-002: Credential Segregation

**Location:** `lib/services/credential_service.dart:18`

Each server has its own credential key, preventing cross-contamination:
```dart
final key = '${AppConstants.credentialKeyPrefix}$serverKey';
```

### ✅ SECURE-003: SQL Injection Protection

**Location:** All repository files

All SQL queries use parameterized queries (`whereArgs`) which prevent SQL injection:
```dart
await db.query(
  'servers',
  where: 'id = ?',
  whereArgs: [id],  // Properly parameterized
);
```

### ✅ SECURE-004: Credential Cleanup on Server Deletion

**Location:** `lib/data/repositories/server_repository.dart:63-78`

When a server is deleted, its credentials are also removed from secure storage:
```dart
if (server != null) {
  await CredentialService.deleteCredential(server.credentialKey);
}
```

### ✅ SECURE-005: Connection Timeouts

**Location:** `lib/services/ssh_service.dart:69`, `lib/core/constants.dart`

SSH connections have appropriate timeouts to prevent hanging:
```dart
timeout: const Duration(seconds: 20),
```

### ✅ SECURE-006: Command Timeouts

**Location:** `lib/services/ssh_service.dart:102-134`

Commands have timeouts to prevent indefinite execution:
```dart
if (stopwatch.elapsed > timeout) {
  throw TimeoutException('Command timed out...');
}
```

---

## 5. Recommendations Summary

### Immediate (Before Production):
1. **Implement host key verification** (CRITICAL-001)
2. **Add command sanitization** for all tmux/screen commands (CRITICAL-002)
3. **Fix exit code detection** (MEDIUM-004)

### Short-term:
4. Implement session name randomization (HIGH-002)
5. Add encryption for execution output (MEDIUM-003)
6. Sanitize error messages (MEDIUM-001)

### Long-term:
7. Consider encrypted database (LOW-001)
8. Document memory safety limitations
9. Implement certificate-based authentication option
10. Add audit logging for security events

---

## 6. Risk Assessment

| Risk | Likelihood | Impact | Priority |
|------|-----------|--------|----------|
| MITM Attack (no host key verify) | Medium | Critical | **BLOCKING** |
| Command Injection | Medium | Critical | **BLOCKING** |
| Credential Memory Leak | Low | High | High |
| Session Hijacking | Low | Medium | Medium |
| Data Exposure | Low | Medium | Medium |

---

## 7. Compliance Notes

- **OWASP Mobile Top 10:**
  - M1: Improper Platform Usage (Partial - host key verification missing)
  - M2: Insecure Data Storage (Mitigated - credentials properly secured)
  - M7: Client Code Quality (Command injection vulnerability)

- **Security Requirements Not Met:**
  - Network security (MITM protection)
  - Input validation (command sanitization)

---

**Report Prepared By:** Security Engineer  
**Status:** 🔴 BLOCKING - Requires fixes before release

**Next Steps:**
1. Address CRITICAL-001 and CRITICAL-002 immediately
2. Re-review after fixes implemented
3. Consider security testing with tools like MobSF
