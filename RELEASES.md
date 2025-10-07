# Release Process

This document describes the release process for the Zsh Autocomplete Plugin.

## Version Numbering

This project follows [Semantic Versioning](https://semver.org/):

**Format**: `vMAJOR.MINOR.PATCH`

- **MAJOR**: Breaking changes (incompatible API changes)
- **MINOR**: New features (backward-compatible functionality)
- **PATCH**: Bug fixes (backward-compatible fixes)

### Examples

- `v1.0.0`: Initial stable release
- `v1.1.0`: Added fuzzy matching feature
- `v1.1.1`: Fixed memory leak in trie operations
- `v2.0.0`: Changed command-line interface (breaking change)

## Creating a Release

### Prerequisites

1. All changes merged to `main` branch
2. All CI checks passing
3. No open critical bugs
4. Documentation updated
5. CHANGELOG prepared (if applicable)

### Release Steps

#### Method 1: Automatic Release (Recommended)

Create a release using GitHub's workflow dispatch:

```bash
# Push changes to main
git checkout main
git pull origin main

# Tag the release
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

The GitHub Actions workflow will automatically:
1. Create a GitHub Release
2. Build binaries for Linux and macOS
3. Package all essential files
4. Upload release artifacts
5. Generate changelog from git commits

#### Method 2: Manual Release Trigger

You can also trigger a release manually from the GitHub Actions tab:

1. Go to **Actions** tab in GitHub
2. Select **Release** workflow
3. Click **Run workflow**
4. Enter the version tag (e.g., `v1.0.0`)
5. Click **Run workflow**

### Release Package Contents

Each release includes:

```
zsh_plugin/
├── autocomplete          # Pre-built binary (platform-specific)
├── plugin.zsh           # Zsh plugin integration
├── README.md            # Project overview
├── SETUP.md             # Installation guide
├── Makefile             # Build configuration
├── scripts/
│   └── setup.sh        # Installation script
├── src/
│   ├── autocomplete.c  # C source code
│   └── trie.c
└── include/
    └── trie.h
```

### Platform-Specific Builds

Two platform packages are created for each release:

| Platform | Package Name                      | Target Architecture |
|----------|-----------------------------------|---------------------|
| Linux    | autocomplete-linux-amd64.tar.gz   | x86_64              |
| macOS    | autocomplete-macos-arm64.tar.gz   | ARM64 (Apple Silicon) |

**Note**: Users on Intel Macs can also use the macOS package (universal compatibility), or build from source.

## Release Checklist

Before creating a release, ensure:

- [ ] All tests pass (`make test`)
- [ ] Code compiles without warnings (`make clean && make`)
- [ ] Documentation is up-to-date
- [ ] Version number is correct in relevant files
- [ ] SETUP.md reflects any installation changes
- [ ] README.md is accurate
- [ ] No debugging code or temporary files
- [ ] Git working directory is clean

## Post-Release

After a release is created:

1. **Verify Release Artifacts**
   - Check that both platform packages are uploaded
   - Verify package sizes are reasonable (typically 25-30 KB)
   - Test downloading and extracting packages

2. **Test Installation**
   ```bash
   # Download and test the release package
   curl -L -o test.tar.gz <release-url>
   tar -xzf test.tar.gz
   cd zsh_plugin
   ./scripts/setup.sh
   ```

3. **Update Documentation**
   - Update README.md if installation steps changed
   - Add release notes (optional)
   - Announce release (if applicable)

## Rollback Procedure

If a release has critical issues:

1. **Delete the GitHub Release** (if not yet widely distributed)
   - Go to Releases page
   - Click the problematic release
   - Click "Delete release"
   - Delete the associated tag: `git push --delete origin v1.0.0`

2. **Create a Patch Release**
   - Fix the critical issue
   - Create a new patch release (e.g., `v1.0.1`)
   - Document the fix in release notes

## Development Releases

For testing purposes, you can create pre-release versions:

```bash
# Create a pre-release tag
git tag -a v1.1.0-beta.1 -m "Beta release for testing"
git push origin v1.1.0-beta.1
```

Mark the release as "pre-release" in GitHub to indicate it's not production-ready.

## Release Frequency

- **Patch releases**: As needed for critical bugs
- **Minor releases**: When new features are stable
- **Major releases**: When breaking changes are necessary

## GitHub Actions Workflow

The release workflow (`.github/workflows/release.yml`) performs:

1. **Checkout**: Fetches repository with full git history
2. **Version Detection**: Extracts version from git tag
3. **Changelog Generation**: Creates changelog from git commits
4. **Release Creation**: Creates GitHub Release with description
5. **Build Binaries**: Compiles optimized binaries for each platform
6. **Testing**: Runs `make test` to verify binaries
7. **Packaging**: Creates tar.gz archives with all essential files
8. **Upload**: Attaches packages to GitHub Release

## Troubleshooting

### Build Failures

If the release build fails:

1. Check CI logs in GitHub Actions
2. Test build locally: `make clean && make`
3. Verify all source files are committed
4. Check for platform-specific compilation issues

### Missing Artifacts

If release packages are missing:

1. Check that `build-binaries` job completed successfully
2. Verify GitHub token permissions (needs `contents: write`)
3. Check artifact upload logs

### Version Conflicts

If the tag already exists:

```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push --delete origin v1.0.0

# Create new tag
git tag -a v1.0.0 -m "Release v1.0.0"
git push origin v1.0.0
```

## Support

For questions about releases:
- Check existing releases for examples
- Review GitHub Actions logs for failures
- Open an issue for release-related problems

---

Last updated: 2024
