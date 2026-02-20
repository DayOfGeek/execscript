# ADR 001: ExecScript Architecture

## Context
ExecScript is a mobile application for managing and executing scripts on remote Linux servers via SSH. It requires a secure, local-first architecture to handle sensitive credentials and direct server communication.

## Decision
We will use **Flutter** as the primary framework for cross-platform mobile development (Android/iOS).

### Key Components:
1.  **State Management:** Riverpod (for dependency injection and state management).
2.  **Navigation:** GoRouter (declarative routing).
3.  **Local Database:** Isar (NoSQL, high performance, encryption support) for structured data (Servers, Scripts, Logs).
4.  **Secure Storage:** `flutter_secure_storage` for sensitive credentials (passwords, private keys).
5.  **SSH Client:** `dartssh2` (Pure Dart SSH implementation).

### Rationale
- **Flutter:** Allows a single codebase for both Android and iOS, with excellent performance and UI customization capabilities (crucial for the cyberpunk aesthetic).
- **Local-First:** Ensures data privacy and security by keeping all sensitive information on the user's device. No backend server is required, reducing complexity and potential attack vectors.
- **Isar:** Offers better performance than SQLite for mobile apps and supports encryption out of the box.
- **dartssh2:** A pure Dart implementation of SSH2, avoiding platform-specific native code bindings which can complicate build processes.

## Consequences
- **Pros:**
    - Cross-platform support.
    - High performance.
    - Secure local storage.
    - Simplified deployment (no backend infrastructure).
- **Cons:**
    - Larger app size due to Flutter runtime.
    - Dependency on `dartssh2` maintenance (though it is actively maintained).

## Status
Proposed

## Date
2026-02-19
