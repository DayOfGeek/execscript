# ExecScript Development Plan

## Overview
ExecScript is a mobile-first application for managing and executing scripts on remote Linux servers via SSH. It serves as the spiritual successor to "Script Kitty", focusing on security, usability, and a distinct cyberpunk aesthetic.

## Architecture & Tech Stack

### Core Technology
- **Framework:** Flutter (Dart)
- **Target Platforms:** Android, iOS
- **Architecture:** Local-First (No backend server required)
- **State Management:** Riverpod
- **Navigation:** GoRouter

### Data Layer
- **Local Database:** Isar or SQLite (drift) for structured data (Servers, Scripts, Logs).
- **Secure Storage:** `flutter_secure_storage` for sensitive credentials (passwords, private keys).
- **SSH Client:** `dartssh2` (Pure Dart SSH implementation).

### Key Components
1.  **Inventory Manager:** CRUD operations for Servers (Host, Port, User, Auth Method).
2.  **Script Library:** CRUD operations for Scripts (Name, Description, Content, Tags).
3.  **Execution Engine:** Handles SSH connection, command execution, output streaming, and error handling.
4.  **Security Module:** Manages keys, passwords, and host verification.

## Security Considerations (Critical)
- **Credential Storage:** NEVER store passwords or private keys in plain text. Use platform-specific secure storage (Keychain/Keystore).
- **Host Verification:** Implement strict host key verification (TOFU - Trust On First Use). Warn users on key changes.
- **Database Encryption:** Encrypt the local database at rest (e.g., SQLCipher).
- **App Access:** Require biometric authentication or PIN to access the app or execute sensitive scripts.

## Development Phases

### Phase 1: Foundation & Security
- Set up Flutter project structure.
- Implement secure storage for credentials.
- Implement basic SSH connectivity with `dartssh2`.
- Establish database schema for Servers and Scripts.

### Phase 2: Inventory & Library Management
- Build UI for adding/editing Servers.
- Build UI for adding/editing Scripts.
- Implement tagging/categorization for Scripts.
- Create association logic (assign scripts to servers or groups).

### Phase 3: Execution Engine
- Implement script execution logic.
- Handle stdout/stderr streaming.
- Implement timeout and cancellation logic.
- Parse exit codes for success/failure status.

### Phase 4: Advanced Features
- **Script Arguments:** Allow parameterized scripts (e.g., `docker restart $container_name`).
- **Snippets:** Reusable code blocks within scripts.
- **History & Logs:** Store execution history and output logs.
- **Batch Execution:** Run a script on multiple servers simultaneously.

### Phase 5: Polish & Release
- Refine UI/UX with Cyberpunk aesthetic (ExecPrompt style).
- Comprehensive testing (Unit, Widget, Integration).
- Prepare for app store submission.

## Next Steps
1.  Initialize the Flutter project in `execscript`.
2.  Set up the project structure following the `execprompt` style guide.
3.  Begin Phase 1 implementation.
