# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- Logo and brand assets (neon green theme)
- OSS community files (CONTRIBUTING, CODE_OF_CONDUCT, SECURITY)
- GitHub issue and PR templates
- Architecture and development documentation

## [0.2.0] - 2026-03-16

### Added
- `-v`/`--verbose` flag for API diagnostics on stderr
- Dependency check at startup (gh, jq, curl)
- Repo metadata validation gate
- PyPI/npm package ownership validation via repository URL
- Input validation on `-r` flag format
- URL-encoding for package names in API calls
- Dynamic output filename: `owner_repo_YYYYMMDD.md`
- Smoke test suite (`test.sh`, 16 tests)
- `.gitignore` for generated reports
- `TODOS.md` with future work items

### Changed
- Redesigned report format — key metrics on top, concise layout
- Daily clone/view tables collapsed in `<details>` tags
- Referrers and popular content sections only shown when data exists
- Commit count now uses contributors API sum with git fallback
- Extended `gh_api` helper with optional default parameter

### Removed
- Dead variables (STARGAZERS, ISSUES_OPEN/CLOSED, COMMIT_COUNT_30D)
- False positive package matches (e.g., unrelated npm packages with same name)

### Fixed
- Broken metadata table in report header
- Redundant jq queries in referrers/popular content sections

## [0.1.0] - 2026-03-15

### Added
- Initial release
- GitHub API integration (traffic, community, releases, contributors)
- PyPI and npm package registry stats
- Real users vs bots confidence-rated estimate
- Markdown report output
