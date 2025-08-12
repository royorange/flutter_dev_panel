# GitHub Actions Workflows

## Publishing to pub.dev

### Setup

1. **Get your pub.dev credentials**:
   ```bash
   cat ~/.config/dart/pub-credentials.json
   ```

2. **Add to GitHub Secrets**:
   - Go to Settings → Secrets and variables → Actions
   - Create a new secret named `PUB_CREDENTIALS`
   - Paste the entire content of pub-credentials.json

### Usage

#### Option 1: Tag-based Publishing (Recommended)

Create a git tag to automatically publish:

```bash
# For main package
git tag v0.0.2
git push origin v0.0.2

# For sub-packages
git tag flutter_dev_panel_console-v0.0.2
git push origin flutter_dev_panel_console-v0.0.2
```

#### Option 2: Manual Publishing

1. Go to Actions tab in GitHub
2. Select "Publish to pub.dev" workflow
3. Click "Run workflow"
4. Select:
   - Package to publish
   - Whether to do a dry run
5. Click "Run workflow"

### Version Management

Before publishing, update the version in the appropriate `pubspec.yaml`:
- Main package: `/pubspec.yaml`
- Sub-packages: `/packages/[package_name]/pubspec.yaml`

### Workflow Features

- **Automatic testing** before publishing
- **Dry run option** for testing
- **Dependency management** - automatically updates sub-package dependencies
- **Tag-based triggers** - publish on version tags
- **Manual triggers** - publish specific packages on demand

### Best Practices

1. Always test locally first:
   ```bash
   flutter pub publish --dry-run
   ```

2. Update CHANGELOG.md before publishing

3. Use semantic versioning:
   - MAJOR.MINOR.PATCH
   - 0.0.x for initial development
   - 0.x.0 for pre-release with breaking changes
   - 1.0.0 for first stable release

4. Tag releases for tracking:
   ```bash
   git tag -a v0.0.2 -m "Release version 0.0.2"
   git push origin v0.0.2
   ```