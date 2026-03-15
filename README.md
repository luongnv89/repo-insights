# repo-insights

Generate comprehensive GitHub repo insights — real users vs bots, traffic, referrers, and package registry stats. All output written to a clean markdown report.

## Why?

PyPI and npm download counts are inflated by bots, CI pipelines, mirrors, and security scanners. You can't tell how many **real humans** actually use your project. This script gives you the answer by combining:

- **GitHub traffic data** (unique cloners and visitors — de-duplicated by GitHub)
- **Referrer analysis** (where your visitors come from)
- **Package registry stats** (PyPI + npm, with ownership validation to avoid false matches)
- **Community signals** (stars, forks, contributors, issues)

## Quick Start

### Run from anywhere (no install)

```bash
curl -fsSL https://raw.githubusercontent.com/luongnv89/repo-insights/main/repo-insights.sh | bash
```

This runs inside your current directory and auto-detects the GitHub repo from `git remote`.

For a specific repo:

```bash
curl -fsSL https://raw.githubusercontent.com/luongnv89/repo-insights/main/repo-insights.sh | bash -s -- -r owner/repo
```

### Clone and run locally

```bash
git clone https://github.com/luongnv89/repo-insights.git
cd repo-insights
./repo-insights.sh -r owner/repo
```

## Usage

```bash
./repo-insights.sh                        # Current repo → owner_repo_YYYYMMDD.md
./repo-insights.sh -r owner/repo          # Specific repo
./repo-insights.sh -o my-report.md        # Custom output file
./repo-insights.sh -v                     # Verbose mode (API diagnostics)
./repo-insights.sh -r owner/repo -o report.md -v  # All options
```

### Options

| Flag | Description |
|------|-------------|
| `-r`, `--repo` | GitHub repo in `owner/repo` format (default: auto-detect from git remote) |
| `-o`, `--output` | Output file path (default: `owner_repo_YYYYMMDD.md`) |
| `-v`, `--verbose` | Show API diagnostics on stderr |
| `-h`, `--help` | Show help |

## Requirements

- **[gh](https://cli.github.com/)** — GitHub CLI (authenticated with `gh auth login`)
- **[jq](https://jqlang.github.io/jq/)** — JSON processor
- **[curl](https://curl.se/)** — for package registry checks
- **git** — for repo detection

The script checks for these dependencies at startup and exits with a clear message if any are missing.

> Note: Traffic data (clones, views, referrers) requires **push access** to the repo. If you don't have push access, those sections will show zeros.

## Report Sections

The generated markdown report includes:

| Section | What it shows |
|---------|---------------|
| **Key Metrics** | Stars, forks, watchers, contributors, open issues, total commits |
| **Traffic** | Page views + clones with unique counts (last 14 days), collapsible daily breakdown |
| **Top Referrers** | Where your visitors come from (shown only when data exists) |
| **Popular Content** | Most visited pages in your repo (shown only when data exists) |
| **Real Users vs Bots** | Confidence-rated estimate of actual users |
| **Package Downloads** | PyPI and npm versions + download counts (only if package links back to repo) |
| **Activity** | Issues, PRs, merged PRs (last 30 days) |
| **Releases** | Latest releases with per-release download counts |
| **Top Contributors** | Ranked by commit count (top 10) |

## Example Output

```
Quick summary:
  Stars: 55 | Forks: 3 | Contributors: 2
  Unique cloners (14d): 133 | Unique visitors (14d): 76
  PyPI: v1.11.1 (1317 downloads/month)
  npm: v1.10.0 (572 downloads/month)
```

### Real Users vs Bots (from generated report)

| Signal | Value | Confidence |
|--------|------:|:----------:|
| Unique cloners (14d) | **133** | `HIGH` |
| Unique visitors (14d) | **76** | `HIGH` |
| Stars | **55** | `HIGH` |
| PyPI downloads/month | 1,317 | `LOW` |
| npm downloads/month | 572 | `LOW` |

**Key insight**: The 133 unique cloners is the most reliable metric — each represents a real person who cloned the repo. The 1,317 PyPI downloads are ~10x inflated by bots and mirrors.

## How it works

1. Checks dependencies (`gh`, `jq`, `curl`) and validates inputs
2. Detects the GitHub repo from `git remote` or `-r` flag
3. Fetches data from GitHub API (traffic, community, releases, contributors)
4. Checks PyPI and npm registries — validates package ownership via repository/homepage URL before including stats
5. Generates a structured markdown report with tables and analysis

All data comes from public APIs. Traffic data (clones, views, referrers) requires push access to the repo.

## Testing

```bash
./test.sh
```

Runs a smoke test that validates the script produces a correctly structured report.

## License

MIT
