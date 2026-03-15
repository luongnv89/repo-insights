# Contributing to RepoInsights

Thanks for your interest in contributing! This guide will help you get started.

## Development Setup

1. **Fork and clone** the repository:
   ```bash
   git clone https://github.com/YOUR_USERNAME/repo-insights.git
   cd repo-insights
   ```

2. **Install dependencies** — the script requires:
   - [gh](https://cli.github.com/) (authenticated with `gh auth login`)
   - [jq](https://jqlang.github.io/jq/)
   - [curl](https://curl.se/)
   - git

3. **Run the smoke tests** to verify your setup:
   ```bash
   ./test.sh
   ```

## How to Contribute

### Reporting Bugs

Open a [bug report](https://github.com/luongnv89/repo-insights/issues/new?template=bug_report.md) with:
- Steps to reproduce
- Expected vs actual behavior
- Your environment (OS, `gh --version`, `jq --version`)

### Suggesting Features

Open a [feature request](https://github.com/luongnv89/repo-insights/issues/new?template=feature_request.md). Check [TODOS.md](TODOS.md) first — your idea might already be planned.

### Submitting Code

1. Create a feature branch from `main`:
   ```bash
   git checkout -b feat/your-feature
   ```

2. Make your changes. Follow these guidelines:
   - Keep the script self-contained (single file, no extra dependencies beyond gh/jq/curl/git)
   - Use `set -euo pipefail` error handling patterns
   - Add verbose logging for new API calls: `verbose "description"`
   - Handle errors gracefully with `|| fallback` patterns

3. Run the smoke tests:
   ```bash
   ./test.sh
   ```

4. Check syntax:
   ```bash
   bash -n repo-insights.sh
   ```

5. Commit using [Conventional Commits](https://www.conventionalcommits.org/):
   ```
   feat: add support for Cargo.toml package detection
   fix: handle repos with no contributors
   docs: update README with new flag
   ```

6. Open a Pull Request against `main`.

## Branching Strategy

- `main` — stable, production-ready
- `feat/*` — new features
- `fix/*` — bug fixes
- `docs/*` — documentation changes

## Code Style

- Bash with `set -euo pipefail`
- Use the `gh_api`, `safe_jq`, `verbose`, and `urlencode` helpers
- Quote all variable expansions: `"$VAR"` not `$VAR`
- Use `[[ ]]` for conditionals, not `[ ]`
- Add comments for non-obvious logic

## Testing

All changes should pass the existing smoke tests (`./test.sh`). If you add a new feature, add a corresponding test case.

## Code of Conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). Be respectful and constructive.

## Questions?

Open a [discussion](https://github.com/luongnv89/repo-insights/issues) or reach out via an issue.
