# Changelog

All notable changes to ExecScript will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- TBD

## [1.0.0] - 2026-02-19

### Added
- Initial open source release
- Direct SSH connections with host key verification
- Script library with variable injection (`{{variable}}` syntax)
- Real-time terminal output streaming
- Background execution via tmux/screen integration
- 5 cyberpunk terminal themes (Amber, Green, Blue, Red, White)
- Password and SSH key authentication (RSA/ED25519)
- Server management with fingerprint verification
- Execution history with status tracking
- Cross-platform support (Android, iOS, Web)
- Offline script library with local storage
- MITM protection through host key verification
- Secure credential storage using platform Keychain/Keystore
- GPL v3 license

### Security
- Host key verification prevents MITM attacks
- Secure credential storage
- Direct SSH connections (no backend service)
- No telemetry or data collection
- Complete security audit documentation

---

## Release Template

```markdown
## [X.Y.Z] - YYYY-MM-DD

### Added
- New features

### Changed
- Changes in existing functionality

### Deprecated
- Soon-to-be removed features

### Removed
- Now removed features

### Fixed
- Bug fixes

### Security
- Security improvements
```
