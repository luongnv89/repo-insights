# repo-insights

Generate comprehensive GitHub repo insights — real users vs bots, traffic, referrers, and package registry stats. All output written to a clean markdown report.

## Why?

PyPI and npm download counts are inflated by bots, CI pipelines, mirrors, and security scanners. You can't tell how many **real humans** actually use your project. This script gives you the answer by combining:

- **GitHub traffic data** (unique cloners and visitors — de-duplicated by GitHub)
- **Referrer analysis** (where your visitors come from)
- **Package registry stats** (PyPI + npm, with bot caveat)
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
./repo-insights.sh                        # Current repo → repo-insights.md
./repo-insights.sh -r owner/repo          # Specific repo
./repo-insights.sh -o my-report.md        # Custom output file
./repo-insights.sh -r owner/repo -o report.md   # Both
```

### Options

| Flag | Description |
|------|-------------|
| `-r`, `--repo` | GitHub repo in `owner/repo` format (default: auto-detect from git remote) |
| `-o`, `--output` | Output file path (default: `repo-insights.md`) |
| `-h`, `--help` | Show help |

## Requirements

- **[gh](https://cli.github.com/)** — GitHub CLI (authenticated with `gh auth login`)
- **[jq](https://jqlang.github.io/jq/)** — JSON processor
- **git** — for repo detection

> Note: Traffic data (clones, views, referrers) requires **push access** to the repo. If you don't have push access, those sections will be empty.

## Report Sections

The generated markdown report includes:

| Section | What it shows |
|---------|---------------|
| **Overview** | Description, language, license, size, dates |
| **Community** | Stars, forks, watchers, contributors, open issues |
| **Traffic** | Daily clones + views with unique counts (14 days) |
| **Top Referrers** | Where your visitors come from (reddit, google, etc.) |
| **Popular Content** | Most visited pages in your repo |
| **Package Stats** | PyPI and npm versions + download counts |
| **Releases** | Release history with asset download counts |
| **Issues & PRs** | Recent activity counts |
| **Top Contributors** | Ranked by commit count |
| **Real vs Bots** | Confidence-rated estimate of actual users |

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
|--------|-------|------------|
| GitHub unique cloners (14d) | **133** | High |
| GitHub unique visitors (14d) | **76** | High |
| GitHub stars | **55** | High |
| PyPI downloads (month) | 1,317 | Low — includes bots |
| npm downloads (month) | 572 | Low — includes bots |

**Key insight**: The 133 unique cloners is the most reliable metric — each represents a real person who cloned the repo. The 1,317 PyPI downloads are ~10x inflated by bots and mirrors.

## How it works

1. Detects the GitHub repo from `git remote` or `-r` flag
2. Fetches data from GitHub API (traffic, community, releases, contributors)
3. Checks PyPI and npm registries for package stats
4. Generates a structured markdown report with tables and analysis

All data comes from public APIs. Traffic data (clones, views, referrers) requires push access to the repo.

## License

MIT
