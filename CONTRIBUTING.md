# Contributing to IronUI

Thank you for your interest in contributing to IronUI! This document provides guidelines and information for contributors.

## Code of Conduct

Please be respectful and constructive in all interactions. We're building something together.

## Getting Started

### Prerequisites

- macOS 15.0+ (for development)
- Xcode 16.0+
- Swift 6.0+

### Setup

1. Fork the repository
2. Clone your fork:
   ```bash
   git clone https://github.com/YOUR_USERNAME/IronUI.git
   cd IronUI
   ```
3. Open in Xcode or build from command line:
   ```bash
   swift build
   ```

### Running Tests

```bash
swift test
```

## Development Guidelines

### Branch Strategy

- **Never commit directly to `main`**
- Create feature branches: `feat/component-name`
- Create fix branches: `fix/issue-description`
- Use stacked PRs for large features

### Commit Messages

Use [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(IronButton): add loading state support
fix(IronTextField): correct placeholder color in dark mode
docs(README): update installation instructions
test(IronAvatar): add snapshot tests for status badges
```

### Code Style

- Follow the [Airbnb Swift Style Guide](https://github.com/airbnb/swift)
- Run the formatter before committing:
  ```bash
  swift package --allow-writing-to-package-directory format
  ```
- Swift 6 strict concurrency compliance is required
- All public APIs must have DocC documentation

### Component Guidelines

When creating or modifying components:

1. **Use IronUI Primitives** - Prefer `IronText` over `Text`, `IronIcon` over `Image`, etc.
2. **Support Theming** - Use `@Environment(\.ironTheme)` for colors, spacing, etc.
3. **Ensure Accessibility** - Add proper labels, traits, and Dynamic Type support
4. **Follow Soft UI Principle** - Avoid overlapping shapes that create hard edges
5. **Add Tests** - Include unit tests and snapshot tests

### Preview Guidelines

Use `@Previewable` for stateful previews:

```swift
#Preview("Component - Interactive") {
    @Previewable @State var value = false

    MyComponent(isEnabled: $value)
        .padding()
}
```

### Accessibility Requirements

All components must:

- Provide meaningful accessibility labels
- Support Dynamic Type scaling
- Respect reduced motion preferences
- Maintain WCAG contrast ratios

## Pull Request Process

1. **Create a focused PR** - One feature or fix per PR
2. **Update documentation** - Add/update DocC comments for API changes
3. **Add tests** - Include unit tests and snapshot tests
4. **Run all tests** - Ensure `swift test` passes
5. **Format code** - Run the formatter
6. **Write a clear description** - Explain what and why

### PR Template

```markdown
## Summary
Brief description of changes

## Changes
- Change 1
- Change 2

## Test Plan
- [ ] Unit tests added/updated
- [ ] Snapshot tests added/updated
- [ ] Manual testing completed

## Screenshots (if applicable)
Before/after screenshots for UI changes
```

## Reporting Issues

When reporting bugs:

1. Check existing issues first
2. Use a clear, descriptive title
3. Include:
   - iOS/macOS version
   - Xcode version
   - Steps to reproduce
   - Expected vs actual behavior
   - Screenshots/videos if applicable

## Feature Requests

We welcome feature requests! Please:

1. Check if it's already requested
2. Explain the use case
3. Describe the proposed API
4. Consider accessibility implications

## Questions?

- Open a [Discussion](https://github.com/Iron-Ham/IronUI/discussions) for questions
- Check the [Documentation](https://iron-ham.github.io/IronUI/)

## License

By contributing, you agree that your contributions will be licensed under the MIT License.
