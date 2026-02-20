# Contributing to ExecScript

Thank you for your interest in contributing to ExecScript! We welcome contributions from the community and are excited to see what you build.

## 🤝 Code of Conduct

This project and everyone participating in it is governed by our commitment to:

- **Be respectful** — Treat everyone with respect. Healthy debate is encouraged, but harassment is not tolerated.
- **Be constructive** — Provide constructive feedback and be open to receiving it.
- **Be inclusive** — Welcome newcomers and help them learn. Use inclusive language.
- **Focus on what's best** — Prioritize the community and users of the project.

## 🔐 Reporting Security Issues

**DO NOT** file a public issue for security vulnerabilities.

Instead, please:
- Email security@dayofgeek.com with details
- Include steps to reproduce (if applicable)
- Allow time for the issue to be addressed before public disclosure

See [SECURITY.md](SECURITY.md) for more details.

## 🚀 Development Setup

### Prerequisites

- Flutter SDK 3.x or higher
- Dart SDK (comes with Flutter)
- Android Studio or Xcode (for mobile builds)
- Git

### Setting Up Your Environment

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR_USERNAME/execscript.git
   cd execscript
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Generate code (if needed):**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run tests to ensure everything works:**
   ```bash
   flutter test
   ```

5. **Run the app:**
   ```bash
   flutter run
   ```

## 📝 Pull Request Process

1. **Create a branch** for your feature or bug fix:
   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Make your changes** following our coding standards.

3. **Add tests** for new functionality or bug fixes.

4. **Ensure all tests pass:**
   ```bash
   flutter test
   ```

5. **Update documentation** if necessary (README, comments, etc.)

6. **Commit your changes** with a clear commit message:
   ```bash
   git commit -m "feat: add feature X"
   ```

7. **Push to your fork:**
   ```bash
   git push origin feature/your-feature-name
   ```

8. **Open a Pull Request** against the `main` branch.

## 🎯 Coding Standards

### General Guidelines

- **Follow existing patterns** — Look at how similar features are implemented and follow the same patterns.
- **Write clean, readable code** — Code is read more often than it's written.
- **Keep functions small and focused** — Single responsibility principle.
- **Add comments** — Explain "why" not "what" (code explains what).
- **Use meaningful names** — Variables, functions, and classes should be descriptive.

### Flutter/Dart Specific

- Follow the [Effective Dart](https://dart.dev/guides/language/effective-dart) style guide
- Use `flutter analyze` to catch issues
- Format code with `dart format .`
- Maximum line length: 80 characters
- Use trailing commas for better diffs

### File Organization

```
lib/
├── core/           # Constants, utilities, theme
├── data/           # Models and repositories
├── presentation/   # UI screens and widgets
│   ├── screens/
│   ├── widgets/
│   ├── providers/
│   └── forms/
└── services/       # Business logic and SSH services
```

### Testing Requirements

- **Unit tests** for all business logic
- **Widget tests** for UI components
- **Integration tests** for critical user flows
- Aim for **80%+ test coverage** for new code

## 🏷️ Commit Message Format

We follow [Conventional Commits](https://www.conventionalcommits.org/):

```
type(scope): description

[optional body]

[optional footer]
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, semicolons, etc.)
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `chore`: Build process or auxiliary tool changes

### Examples

```
feat(terminal): add support for 256 color themes

fix(ssh): handle connection timeout gracefully

docs(readme): update installation instructions

test(execution): add tests for background job status
```

## 🔍 Code Review Process

All submissions require review before merging:

1. At least one maintainer approval required
2. All CI checks must pass
3. No merge conflicts
4. Follows coding standards

Reviewers will:
- Check for correctness and edge cases
- Verify test coverage
- Ensure code follows project patterns
- Suggest improvements when applicable

## 🐛 Bug Reports

When filing a bug report, please include:

- **Clear description** of the bug
- **Steps to reproduce** the issue
- **Expected behavior** vs actual behavior
- **Device information** (OS, version, device model)
- **Screenshots** if applicable
- **Logs** if available (redact sensitive info)

Use the bug report template when creating issues.

## 💡 Feature Requests

We love new ideas! When requesting a feature:

- **Describe the problem** you're trying to solve
- **Explain your proposed solution**
- **Consider alternatives** you've thought about
- **Note** if you're willing to implement it

Use the feature request template when creating issues.

## 📜 License

By contributing to ExecScript, you agree that your contributions will be licensed under the GNU General Public License v3.0.

## 🙏 Thank You!

Your contributions help make ExecScript better for everyone. We appreciate your time and effort!

---

**Questions?** Reach out via:
- GitHub Discussions
- Email: contribute@dayofgeek.com
