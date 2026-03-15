# Architecture

RepoInsights is a single-file bash script with no external dependencies beyond `gh`, `jq`, `curl`, and `git`.

## System Design

```
┌──────────────────────────────────────────────────────┐
│                   repo-insights.sh                    │
├──────────────┬───────────────┬────────────────────────┤
│  Input       │  Processing   │  Output                │
│              │               │                        │
│  CLI flags   │  Fetch data   │  Markdown report       │
│  -r, -o, -v  │  Extract      │  owner_repo_DATE.md    │
│              │  Validate     │                        │
│  Auto-detect │  Generate     │  Terminal summary      │
│  from git    │               │                        │
└──────┬───────┴───────┬───────┴────────────────────────┘
       │               │
       ▼               ▼
  ┌─────────┐   ┌──────────────┐
  │  git    │   │  GitHub API  │──── repos/{owner}/{repo}
  │  remote │   │  (via gh)    │──── traffic/clones
  └─────────┘   │              │──── traffic/views
                │              │──── traffic/popular/*
                │              │──── releases
                │              │──── contributors
                │              │──── issues, pulls
                └──────┬───────┘
                       │
                ┌──────┴───────┐
                │ Package APIs │
                │  PyPI (curl) │
                │  npm (curl)  │
                └──────────────┘
```

## Execution Flow

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

## Key Design Decisions

1. **Single file** — No installation, just `curl | bash`. No package manager, no config files.
2. **gh CLI for auth** — Delegates authentication entirely to GitHub's official CLI. No token management.
3. **Package ownership validation** — PyPI/npm packages are only included if their repository URL points back to the GitHub repo. Prevents false matches.
4. **Graceful degradation** — Missing data (no push access, no packages) results in omitted sections, not errors.
5. **Verbose mode** — `-v` flag enables diagnostics on stderr without polluting the report.

## Helpers

| Function | Purpose |
|----------|---------|
| `gh_api` | Wraps `gh api` with fallback default (`{}` or `[]`) |
| `safe_jq` | jq with fallback value on parse failure |
| `verbose` | Conditional stderr logging |
| `urlencode` | URL-encode strings for API calls |
