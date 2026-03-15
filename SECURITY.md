# Security Policy

## Supported Versions

| Version | Supported          |
| ------- | ------------------ |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

RepoInsights is a read-only CLI tool that queries public APIs. Its attack surface is minimal, but we take security seriously.

### How to Report

1. **Do NOT** open a public GitHub issue for security vulnerabilities
2. Email your findings to **luongnv89@gmail.com**
3. Include detailed steps to reproduce the vulnerability
4. Allow up to 48 hours for an initial response

### What to Include

- Type of vulnerability
- Full paths of affected source files
- Step-by-step instructions to reproduce
- Impact of the issue

### What to Expect

- Acknowledgment of your report within 48 hours
- Regular updates on our progress
- Credit in the security advisory (if desired)
- Notification when the issue is fixed

## Security Best Practices

When contributing to this project:

- Never commit secrets, API keys, or credentials
- The script relies on `gh` CLI for authentication — no tokens are stored
- Use `--verbose` flag for debugging, never log sensitive data
- Report any security concerns immediately
