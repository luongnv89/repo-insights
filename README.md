<p align="center">
  <img src="assets/logo/logo-full.svg" alt="RepoInsights" width="420">
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-green.svg" alt="MIT License"></a>
  <a href="https://github.com/luongnv89/repo-insights/releases"><img src="https://img.shields.io/github/v/release/luongnv89/repo-insights" alt="Release"></a>
  <a href="https://github.com/luongnv89/repo-insights/stargazers"><img src="https://img.shields.io/github/stars/luongnv89/repo-insights" alt="Stars"></a>
  <a href="https://github.com/luongnv89/repo-insights/issues"><img src="https://img.shields.io/github/issues/luongnv89/repo-insights" alt="Issues"></a>
</p>

<h1 align="center">Stop Guessing Who Uses Your Project</h1>

<p align="center">
  PyPI and npm download counts lie. RepoInsights cuts through bots, mirrors, and CI noise to show you <strong>real humans</strong> — in one command, one markdown report.
</p>

<p align="center">
  <a href="#get-started-in-30-seconds"><strong>Get Started in 30 Seconds →</strong></a>
</p>

---

## The Problem

You ship an open-source project. You check the numbers. They look great — until you realize they're meaningless:

- **Download counts are 10x inflated.** Bots, CI pipelines, security scanners, and mirrors all count as "downloads." A project with 1,300 monthly PyPI downloads might have 130 real users.
- **You can't tell humans from machines.** npm and PyPI don't distinguish between a developer running `pip install` and a CI job fetching your package 50 times a day.
- **You're flying blind on actual adoption.** Stars are vanity. Downloads are noise. You have no single source of truth for "how many people actually use this?"

Without real numbers, you can't prioritize features, justify continued maintenance, or explain your project's impact to anyone.

## How RepoInsights Fixes This

RepoInsights combines **five data sources** that individually lie but together tell the truth:

- **GitHub-verified unique visitors and cloners** — de-duplicated by GitHub, the highest-confidence signal you can get. Each unique cloner is a real person.
- **Confidence-rated metrics** — every number gets a `HIGH`, `MEDIUM`, or `LOW` confidence label so you know exactly what to trust.
- **Package ownership validation** — before including PyPI/npm stats, RepoInsights verifies the package's repository URL points to your repo. No false matches.
- **Referrer analysis** — see where your visitors actually come from (Google, Hacker News, Reddit, direct links).
- **Community pulse** — stars, forks, contributors, issues, PRs, and release downloads in one consolidated view.

The result: a single markdown report that tells you what's real and what's noise.

## Get Started in 30 Seconds

Run from anywhere — zero install required:

```bash
curl -fsSL https://raw.githubusercontent.com/luongnv89/repo-insights/main/repo-insights.sh | bash
```

This auto-detects the GitHub repo from `git remote` in your current directory.

For a specific repo:

```bash
curl -fsSL https://raw.githubusercontent.com/luongnv89/repo-insights/main/repo-insights.sh | bash -s -- -r owner/repo
```

[**See Full Usage Options →**](#usage)

## See It in Action

Here's what a real report looks like:

```
Quick summary:
  Stars: 55 | Forks: 3 | Contributors: 2
  Unique cloners (14d): 133 | Unique visitors (14d): 76
  PyPI: v1.11.1 (1317 downloads/month)
  npm: v1.10.0 (572 downloads/month)
```

### Real Users vs Bots

| Signal | Value | Confidence |
|--------|------:|:----------:|
| Unique cloners (14d) | **133** | `HIGH` |
| Unique visitors (14d) | **76** | `HIGH` |
| Stars | **55** | `HIGH` |
| PyPI downloads/month | 1,317 | `LOW` |
| npm downloads/month | 572 | `LOW` |

**Key insight**: The 133 unique cloners is the most reliable metric — each represents a real person who cloned the repo. The 1,317 PyPI downloads are ~10x inflated by bots and mirrors.

[**Generate Your Own Report →**](#get-started-in-30-seconds)

## How It Works

1. **Detect** — auto-discovers your GitHub repo from `git remote`, or accepts `owner/repo` directly
2. **Fetch** — pulls data from GitHub API (traffic, community, releases, contributors) and package registries (PyPI, npm)
3. **Validate** — confirms package ownership via repository URL, filters noise, rates confidence
4. **Report** — generates a structured markdown file with tables, analysis, and actionable insights

All data comes from public APIs. No tokens to manage — authentication is handled by `gh` CLI.

[**Try It Now →**](#get-started-in-30-seconds)

## What's in the Report

| Section | What You Learn |
|---------|----------------|
| **Key Metrics** | Stars, forks, watchers, contributors, open issues, total commits |
| **Traffic** | Page views + clones with unique counts (last 14 days) |
| **Top Referrers** | Where your visitors come from |
| **Popular Content** | Most visited pages in your repo |
| **Real Users vs Bots** | Confidence-rated estimate of actual human users |
| **Package Downloads** | PyPI and npm versions + download counts |
| **Activity** | Issues, PRs, merged PRs (last 30 days or all-time) |
| **Releases** | Latest releases with download counts |
| **Top Contributors** | Ranked by commit count |

## FAQ

**Is it free?**
Yes. RepoInsights is MIT licensed, free forever, and open source. Use it for personal projects, at work, wherever.

**What does it need to run?**
Four tools you probably already have: [`gh`](https://cli.github.com/) (GitHub CLI), [`jq`](https://jqlang.github.io/jq/), [`curl`](https://curl.se/), and `git`. The script checks for these at startup and tells you exactly what's missing.

**Can I get all-time stats instead of just the last 14 days?**
Yes. Use the `-a` flag to fetch complete repository history — all issues, PRs, releases, and contributors. Traffic data is still limited to 14 days (a GitHub API restriction), but everything else goes all the way back.

**Why are traffic sections empty or showing zeros?**
Traffic data (clones, views, referrers) requires **push access** to the repo. If you're not a collaborator or owner, those sections will be blank. All other data works with read-only access.

**How does it compare to GitHub Insights?**
GitHub's built-in Insights shows traffic graphs but doesn't combine them with package downloads, confidence ratings, or a downloadable report. RepoInsights gives you the full picture in one file you can share, archive, or track over time.

**Is it maintained?**
Actively. See the [changelog](docs/CHANGELOG.md) for recent releases and the [TODOS](TODOS.md) for what's coming next.

**Can I use it in CI?**
Absolutely. It's a single bash script with no installation step — pipe it with `curl | bash` in any CI environment that has `gh` authenticated.

## Start Knowing Your Real Users

You built something useful. You deserve to know who's actually using it — not what bots and mirrors want you to believe.

RepoInsights is MIT licensed, zero-install, and takes 30 seconds to run.

[**Get Your First Report →**](#get-started-in-30-seconds)

---

<details>
<summary><strong>Usage Reference</strong></summary>

### Usage

```bash
./repo-insights.sh                        # Current repo → owner_repo_YYYYMMDD.md
./repo-insights.sh -r owner/repo          # Specific repo
./repo-insights.sh -o my-report.md        # Custom output file
./repo-insights.sh -v                     # Verbose mode (API diagnostics)
./repo-insights.sh -a                     # All-time stats (paginated)
./repo-insights.sh -r owner/repo -a -v    # All-time for specific repo, verbose
```

### Options

| Flag | Description |
|------|-------------|
| `-r`, `--repo` | GitHub repo in `owner/repo` format (default: auto-detect from git remote) |
| `-o`, `--output` | Output file path (default: `owner_repo_YYYYMMDD.md`) |
| `-v`, `--verbose` | Show API diagnostics on stderr |
| `-a`, `--all` | Fetch all-time stats (paginate all issues, PRs, releases, contributors) |
| `-h`, `--help` | Show help |

### All-Time Mode

Use `-a` / `--all` to fetch complete repository history:

- **Issues & PRs** — all issues and PRs (paginated), with open/closed/merged breakdown
- **Releases** — every release with download counts
- **Contributors** — full contributor list (top 25 shown in report)
- **Package downloads** — PyPI total (~180 day window), npm lifetime total
- **Traffic** — still limited to 14 days (GitHub API restriction)

> All-time mode makes more API requests and may take longer for large repositories.

</details>

<details>
<summary><strong>Requirements</strong></summary>

- **[gh](https://cli.github.com/)** — GitHub CLI (authenticated with `gh auth login`)
- **[jq](https://jqlang.github.io/jq/)** — JSON processor
- **[curl](https://curl.se/)** — for package registry checks
- **git** — for repo detection

The script checks for these dependencies at startup and exits with a clear message if any are missing.

> Note: Traffic data (clones, views, referrers) requires **push access** to the repo. If you don't have push access, those sections will show zeros.

</details>

<details>
<summary><strong>Clone & Run Locally</strong></summary>

```bash
git clone https://github.com/luongnv89/repo-insights.git
cd repo-insights
./repo-insights.sh -r owner/repo
```

</details>

<details>
<summary><strong>Testing</strong></summary>

```bash
./test.sh
```

Runs a smoke test that validates the script produces a correctly structured report.

</details>

<details>
<summary><strong>Architecture</strong></summary>

RepoInsights is a single-file bash script with no external dependencies beyond `gh`, `jq`, `curl`, and `git`.

```
START
  │
  ├─ Check dependencies (gh, jq, curl)
  ├─ Parse CLI arguments
  ├─ Detect or validate repo
  ├─ Generate output filename
  │
  ├─ FETCH PHASE
  │   ├─ Repo metadata → validate response
  │   ├─ Traffic data (clones, views, referrers, paths)
  │   ├─ Community data (releases, contributors)
  │   ├─ Activity data (issues, PRs)
  │   └─ Package registries (PyPI, npm) → validate ownership
  │
  ├─ EXTRACT PHASE
  │   └─ jq parsing with safe defaults
  │
  ├─ GENERATE PHASE
  │   └─ Write markdown sections to output file
  │
  └─ DONE → print summary
```

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for full details.

</details>

<details>
<summary><strong>Contributing</strong></summary>

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

</details>

## License

[MIT](LICENSE) — Luong NGUYEN
