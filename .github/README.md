# .github Directory

This directory contains GitHub-specific configuration files and templates for the zsh_plugin repository.

## Structure

```
.github/
├── workflows/              # GitHub Actions CI/CD pipelines
│   ├── ci.yml             # Continuous Integration
│   ├── release.yml        # Automated releases
│   └── code-quality.yml   # Linting and quality checks
├── ISSUE_TEMPLATE/        # Issue templates
│   ├── bug_report.md      # Bug report template
│   ├── feature_request.md # Feature request template
│   └── config.yml         # Issue template configuration
├── PULL_REQUEST_TEMPLATE.md  # PR template
├── CODEOWNERS             # Code ownership rules
├── dependabot.yml         # Dependency updates configuration
└── README.md              # This file
```

## Purpose

- **Workflows**: Automate building, testing, and releasing
- **Issue Templates**: Standardize bug reports and feature requests
- **PR Template**: Ensure comprehensive pull request descriptions
- **CODEOWNERS**: Define code review responsibilities
- **Dependabot**: Keep dependencies up to date

## Best Practices

1. All CI checks must pass before merging
2. Use issue templates for better bug tracking
3. Follow the PR template for consistency
4. Review CODEOWNERS for approval requirements
