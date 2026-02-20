# EXECSCRIPT

**Mobile SSH script execution for Linux servers.**

[![BUILD](https://img.shields.io/static/v1?label=BUILD&message=PASSING&color=33FF33&labelColor=0A0F0A&style=flat-square)](https://github.com/dayofgeek/execscript/actions)
[![LICENSE](https://img.shields.io/static/v1?label=LICENSE&message=GPL%20v3&color=33FF33&labelColor=0A0F0A&style=flat-square)](https://www.gnu.org/licenses/gpl-3.0)
[![FLUTTER](https://img.shields.io/static/v1?label=FLUTTER&message=3.x&color=E0E0E0&labelColor=0A0F0A&style=flat-square)](https://flutter.dev)
[![PLATFORM](https://img.shields.io/static/v1?label=PLATFORM&message=ANDROID%20%7C%20IOS&color=E0E0E0&labelColor=0A0F0A&style=flat-square)](#)

---

## [SYS] STATUS

```
CLASSIFICATION: OPEN SOURCE
VERSION:        1.0.0
ARCHITECTURE:   DIRECT SSH / NO BACKEND
STATUS:         OPERATIONAL
```

---

## [FEATURES]

```
[>] Direct SSH connections — No backend, no middleman, no tracking
[>] Script library with variable injection — {{variable}} syntax
[>] Real-time terminal streaming — Watch execution as it happens
[>] Background execution via tmux/screen — Disconnect, reconnect
[>] Host key verification — MITM protection built-in
[>] 5 terminal themes — Amber, Green, White, Cyan, Synthwave
[>] Password + SSH key auth — RSA/ED25519 support
[>] Offline script storage — Work without connectivity
[>] Full execution history — Audit trail for every command
```

---

## [EXEC] REQUIREMENTS

```
FLUTTER SDK    >= 3.0
ANDROID SDK    API 21+
XCODE          15+ (iOS builds, macOS only)
GIT            2.x
```

---

## [INSTALL] BUILD PROCEDURE

### Clone

```bash
git clone https://github.com/dayofgeek/execscript.git
cd execscript
```

### Setup

```bash
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

### Run Tests

```bash
flutter test
```

### Build Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle
flutter build appbundle --release

# iOS (macOS + Xcode required)
flutter build ios --release

# Web
flutter build web --release
```

---

## [SECURITY] OVERVIEW

```
ARCHITECTURE:   Local-first, direct SSH
CREDENTIALS:    Platform secure storage (Keychain/Keystore)
ENCRYPTION:     TLS for SSH connections
TELEMETRY:      None
BACKEND:        None
```

### Security Model

- **Direct SSH** — Your device connects directly to servers. No proxy. No cloud.
- **Host key verification** — Server fingerprints validated on first connect
- **Secure credential storage** — Keys and passwords stored in platform keystore
- **Zero telemetry** — No analytics, no crash reports, no tracking

### Reporting Issues

Found a security issue? Email: security@dayofgeek.com

Do not open public issues for security vulnerabilities.

---

## [SCREENS] INTERFACE

| HOME | SCRIPTS | TERMINAL | EXECUTION |
|:----:|:------:|:--------:|:---------:|
| [Coming] | [Coming] | [Coming] | [Coming] |

| SERVERS | JOBS | SETTINGS | THEMES |
|:------:|:----:|:--------:|:------:|
| [Coming] | [Coming] | [Coming] | [Coming] |

---

## [CONTRIBUTE] PROTOCOL

1. Fork the repository
2. Create feature branch (`git checkout -b feature/call-sign`)
3. Write code + tests
4. Run `flutter test`
5. Commit (`git commit -m 'Add call-sign feature'`)
6. Push (`git push origin feature/call-sign`)
7. Open Pull Request

See: [CONTRIBUTING.md](CONTRIBUTING.md)

---

## [LICENSE] LEGAL

```
ExecScript - Mobile SSH Script Execution
Copyright (C) 2026 DayOfGeek.com

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License v3.0
```

File: [LICENSE](LICENSE)

---

## [SUPPORT] OPERATIONS

- [GitHub Sponsors](https://github.com/sponsors/dayofgeek)
- [Patreon](https://patreon.com/dayofgeek)

---

## [CREDITS]

```
INSPIRATION:  Script Kitty
SSH ENGINE:   dartssh2
FRAMEWORK:    Flutter
BRAND:        DayOfGeek.com
```

---

**[DAYOFGEEK.COM](https://dayofgeek.com)**
