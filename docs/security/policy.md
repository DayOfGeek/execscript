# ExecScript Security Policy

## 1. Credential Storage

**Objective:** Prevent unauthorized access to sensitive credentials (passwords, private keys, passphrases) stored on the device.

**Implementation:**
*   **Storage Mechanism:** Use `flutter_secure_storage` to interface with the platform's secure storage mechanisms:
    *   **iOS:** Keychain Services.
    *   **Android:** EncryptedSharedPreferences (backed by Android Keystore).
*   **Data Handling:**
    *   Credentials must **NEVER** be stored in plain text in the local database (Isar/SQLite) or logs.
    *   Credentials should only be loaded into memory when establishing an SSH connection and cleared immediately after use or when the session ends.
    *   Use `SecureString` or similar memory-safe wrappers if available in Dart to minimize memory dump exposure (though Dart's garbage collection makes this challenging, minimizing scope is key).
*   **Key Management:**
    *   If the user provides a private key file, the content of the key must be read and stored securely in `flutter_secure_storage`. Do not rely on the file remaining on the filesystem.
    *   Support for passphrase-protected SSH keys is mandatory. The passphrase should be stored securely alongside the key if the user opts to "remember" it.

## 2. SSH Verification (Trust-On-First-Use)

**Objective:** Prevent Man-in-the-Middle (MitM) attacks by verifying the identity of the remote server.

**Implementation:**
*   **Library:** Use `dartssh2` for SSH connections.
*   **Verification Logic:**
    1.  **First Connection:**
        *   Capture the server's host key fingerprint (SHA-256).
        *   Display the fingerprint to the user and ask for explicit confirmation to trust it.
        *   Store the trusted fingerprint securely, associated with the host and port.
    2.  **Subsequent Connections:**
        *   Retrieve the stored fingerprint for the host.
        *   Compare it with the fingerprint presented by the server during the handshake.
        *   **Match:** Proceed with the connection.
        *   **Mismatch:** **ABORT** the connection immediately. Display a **CRITICAL WARNING** to the user indicating a potential MitM attack or host key change.
*   **User Override:**
    *   Allow the user to manually update the stored fingerprint if they have verified the key change (e.g., server re-installation). This action requires explicit confirmation.
*   **Configuration:**
    *   Disable `StrictHostKeyChecking=no` behavior. Verification must always be active.

## 3. Input Validation

**Objective:** Prevent injection attacks where malicious input could execute unintended commands on the remote server or the local device.

**Implementation:**
*   **Script Arguments:**
    *   Treat all user-supplied arguments as untrusted.
    *   **Sanitization:** Use strict allow-listing for characters (e.g., alphanumeric, specific symbols).
    *   **Escaping:** Properly escape arguments before passing them to the SSH execution command. Use shell-escaping functions provided by the SSH library or a dedicated shell-escaping package to handle special characters (spaces, quotes, semicolons, etc.).
    *   **Parameterization:** If possible, pass arguments as environment variables to the script execution context rather than interpolating them directly into the command string.
        *   *Example:* Instead of `./script.sh $ARG`, use `ARG=$USER_INPUT ./script.sh`.
*   **Script Content:**
    *   While the user writes the scripts, warn them if the script contains dangerous patterns (e.g., `rm -rf /`, `sudo` without flags) via static analysis or linting, but do not block execution as this is a power-user tool.

## 4. Local Authentication

**Objective:** Protect the application and its stored credentials from unauthorized access if the device is unlocked and left unattended or stolen.

**Implementation:**
*   **Requirement:** Enforce local authentication (Biometric or PIN) upon app launch and after a period of inactivity.
*   **Mechanism:** Use the `local_auth` package for Flutter.
*   **Policy:**
    *   **App Start:** Require authentication immediately.
    *   **Resume:** Require authentication if the app has been in the background for more than 1 minute.
    *   **Sensitive Actions:** Require re-authentication before:
        *   Viewing/Copying stored passwords or private keys.
        *   Exporting the database or configuration.
        *   Deleting critical resources (servers, scripts).
*   **Fallback:** Provide a secure fallback (e.g., device PIN/Pattern) if biometrics fail or are unavailable.

## 5. Data Protection

**Objective:** Ensure data privacy and integrity.

**Implementation:**
*   **Database Encryption:**
    *   Encrypt the local database (Isar) using a key derived from a secure source or stored in `flutter_secure_storage`.
*   **Logging:**
    *   **Disable** verbose logging in production builds.
    *   **Redact** sensitive information (passwords, keys, tokens) from all logs.
    *   Logs should strictly contain operational data (connection success/fail, error codes) and not payload data unless explicitly enabled for debugging (and warned).
