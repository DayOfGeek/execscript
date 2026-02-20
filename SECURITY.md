# Security

## Reporting Issues

Found a security issue? Email: security@dayofgeek.com

Do not open public issues for security vulnerabilities.

## Security Model

ExecScript follows these principles:

**Local-First Architecture**
- Your device connects directly to servers via SSH
- No cloud backend, no proxy servers, no middlemen
- All data stays on your device

**Credential Storage**
- SSH keys and passwords stored in platform secure storage
- Android: EncryptedSharedPreferences + Keystore
- iOS: Keychain
- Never written to logs or plain text files

**Connection Security**
- SSH host key verification on first connect
- MITM detection if server keys change
- Shell escaping on all user input (prevents injection)

**Code Transparency**
- GPL v3 licensed — full source available
- Build reproducibly from source
- No telemetry, no analytics, no tracking

## Responsibility

This tool executes commands on remote servers. You are responsible for:
- Verifying server identities (host keys)
- Securing your SSH credentials
- Reviewing scripts before execution
- Understanding what commands do before running them

ExecScript provides the tools. You provide the judgment.

## Dependencies

See pubspec.yaml for full dependency list. Key security-related packages:
- dartssh2: SSH client implementation
- flutter_secure_storage: Platform credential storage
- sqflite: Local SQLite database

## License

GPL v3 — See LICENSE file
