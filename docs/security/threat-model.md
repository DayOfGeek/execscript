# ExecScript Threat Model

## 1. Stolen Device

**Threat:** An attacker gains physical access to the user's unlocked or locked device.
**Impact:** Unauthorized access to stored SSH credentials (private keys, passwords), server inventory, and the ability to execute arbitrary commands on remote servers.
**Risk Level:** **Critical**

**Mitigation Strategies:**
*   **Local Authentication:**
    *   **Requirement:** Enforce biometric or PIN authentication on app launch and resume (after 1 minute of inactivity).
    *   **Implementation:** Use `local_auth` package. Ensure the authentication prompt cannot be bypassed by simply restarting the app or clearing cache.
*   **Secure Storage:**
    *   **Requirement:** Store all sensitive credentials (passwords, private keys) in the platform's secure storage (Keychain/Keystore) via `flutter_secure_storage`.
    *   **Implementation:** Never store credentials in plain text in the local database (Isar) or shared preferences.
*   **Database Encryption:**
    *   **Requirement:** Encrypt the local database at rest.
    *   **Implementation:** Use Isar's built-in encryption with a key stored securely in `flutter_secure_storage`. This prevents an attacker from extracting data by copying the database file.
*   **Remote Wipe:**
    *   **Recommendation:** Advise users to enable remote wipe capabilities (Find My iPhone / Find My Device) on their devices.

## 2. Malicious Scripts

**Threat:** A user imports or copies a script containing malicious commands (e.g., `rm -rf /`, data exfiltration, backdoors) without fully understanding its content.
**Impact:** Data loss, server compromise, or unauthorized access to other systems.
**Risk Level:** **High**

**Mitigation Strategies:**
*   **Script Review:**
    *   **Requirement:** Display the full content of any imported script to the user before saving or executing it.
    *   **Implementation:** Highlight potentially dangerous commands (e.g., `rm`, `sudo`, `dd`, `mkfs`) in the script editor/viewer.
*   **Input Validation:**
    *   **Requirement:** Sanitize and validate all user inputs (arguments) passed to scripts.
    *   **Implementation:** Use strict allow-listing for argument characters. Escape special characters to prevent command injection.
*   **Least Privilege:**
    *   **Recommendation:** Advise users to connect with non-root accounts and use `sudo` only when necessary.
    *   **Implementation:** Display a warning if the configured user is `root`.

## 3. Man-in-the-Middle (MitM) Attacks

**Threat:** An attacker intercepts the SSH connection between the app and the remote server.
**Impact:** Credential theft (passwords), session hijacking, or injection of malicious commands.
**Risk Level:** **Critical**

**Mitigation Strategies:**
*   **Strict Host Key Verification (TOFU):**
    *   **Requirement:** Implement Trust-On-First-Use (TOFU) for SSH host keys.
    *   **Implementation:**
        *   On the first connection, display the server's host key fingerprint and require explicit user approval.
        *   Store the approved fingerprint securely.
        *   On subsequent connections, verify the presented fingerprint against the stored one.
        *   **Abort** the connection immediately if there is a mismatch.
*   **Algorithm Security:**
    *   **Requirement:** Use strong encryption algorithms and key exchange methods.
    *   **Implementation:** Configure `dartssh2` to prefer modern, secure algorithms (e.g., Ed25519, chacha20-poly1305) and disable weak ones (e.g., DSS, 3DES) if possible.

## 4. Data Leakage via Logs/Backups

**Threat:** Sensitive information (credentials, command output) is inadvertently exposed in application logs, system backups, or clipboard history.
**Impact:** Credential theft or exposure of sensitive server data.
**Risk Level:** **Medium**

**Mitigation Strategies:**
*   **Log Redaction:**
    *   **Requirement:** Ensure no sensitive data (passwords, keys) is ever written to application logs.
    *   **Implementation:** Implement a custom logger that filters out known sensitive fields.
*   **Backup Exclusion:**
    *   **Requirement:** Exclude the database and secure storage from cloud backups (iCloud/Google Drive) if they cannot be guaranteed to be encrypted with a user-controlled key.
    *   **Implementation:** Configure the app manifest/plist to exclude specific files or directories from backup.
*   **Clipboard Management:**
    *   **Requirement:** Clear the clipboard after a short timeout if the user copies sensitive data (e.g., a password).
    *   **Implementation:** Use a clipboard manager wrapper that supports timeouts.

## 5. Dependency Vulnerabilities

**Threat:** A vulnerability in a third-party package (e.g., `dartssh2`, `flutter_secure_storage`) is exploited.
**Impact:** Varies depending on the vulnerability (RCE, data leak, DoS).
**Risk Level:** **Medium**

**Mitigation Strategies:**
*   **Regular Audits:**
    *   **Requirement:** Regularly run `flutter pub outdated` and check for security advisories.
    *   **Implementation:** Integrate dependency scanning into the CI/CD pipeline.
*   **Pinning:**
    *   **Requirement:** Pin dependency versions to avoid accidental upgrades to unstable or compromised versions.
    *   **Implementation:** Commit `pubspec.lock` to the repository.
