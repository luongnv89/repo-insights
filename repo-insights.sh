#!/usr/bin/env bash
# repo-insights.sh — Generate a comprehensive GitHub repo insights report
#
# Usage:
#   ./repo-insights.sh                             # Current repo, output to owner_repo_YYYYMMDD.md
#   ./repo-insights.sh -o report.md                # Custom output file
#   ./repo-insights.sh -r owner/repo               # Specific repo
#   ./repo-insights.sh -v                          # Verbose mode (show API diagnostics)
#   curl -fsSL https://raw.githubusercontent.com/luongnv89/repo-insights/main/repo-insights.sh | bash
#
# Requirements: gh (GitHub CLI, authenticated), jq, curl, git

set -euo pipefail

# === DEFAULTS ===
OUTPUT_FILE=""
REPO=""
VERBOSE=false
ALL_TIME=false
DATE_NOW=$(date -u +"%Y-%m-%d %H:%M UTC")
DATE_SHORT=$(date -u +"%Y%m%d")

# === DEPENDENCY CHECK ===
for cmd in gh jq curl; do
    if ! command -v "$cmd" &>/dev/null; then
        echo "Error: '$cmd' is required but not installed. See README for requirements."
        exit 1
    fi
done

# === PARSE ARGS ===
while [[ $# -gt 0 ]]; do
    case "$1" in
        -o|--output) OUTPUT_FILE="$2"; shift 2 ;;
        -r|--repo)   REPO="$2"; shift 2 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -a|--all) ALL_TIME=true; shift ;;
        -h|--help)
            echo "Usage: repo-insights.sh [-r owner/repo] [-o output.md] [-v] [-a]"
            echo "  -r, --repo    GitHub repo (default: auto-detect from git remote)"
            echo "  -o, --output  Output file (default: owner_repo_YYYYMMDD.md)"
            echo "  -v, --verbose Show API diagnostics on stderr"
            echo "  -a, --all     Fetch all-time stats (paginate all issues, PRs, releases, contributors)"
            exit 0 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# === HELPERS ===
verbose() {
    if [[ "$VERBOSE" == true ]]; then
        echo "[verbose] $*" >&2
    fi
}

gh_api() {
    local result
    result=$(gh api "$1" 2>/dev/null || echo "${2:-\{\}}")
    verbose "gh api $1 → ${#result} bytes"
    echo "$result"
}

# Fetch ALL pages from a GitHub API list endpoint, returns merged JSON array
gh_api_all() {
    local result
    result=$(gh api "$1" --paginate --slurp 2>/dev/null | jq 'flatten' 2>/dev/null || echo "${2:-[]}")
    verbose "gh api (paginated) $1 → ${#result} bytes"
    echo "$result"
}

# Safe jq that returns a default on failure
safe_jq() {
    echo "$1" | jq -r "$2" 2>/dev/null || echo "${3:-0}"
}

# URL-encode a string (for package name in API URLs)
urlencode() {
    local string="$1"
    printf '%s' "$string" | jq -sRr @uri
}

# === DETECT REPO ===
if [[ -z "$REPO" ]]; then
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || true)
    if [[ -z "$REPO" ]]; then
        echo "Error: Could not detect repo. Use -r owner/repo or run inside a git repo."
        exit 1
    fi
fi

# Validate repo format
if [[ ! "$REPO" =~ ^[A-Za-z0-9._-]+/[A-Za-z0-9._-]+$ ]]; then
    echo "Error: Invalid repo format '$REPO'. Expected owner/repo."
    exit 1
fi

# === DEFAULT OUTPUT FILENAME ===
if [[ -z "$OUTPUT_FILE" ]]; then
    OUTPUT_FILE="${REPO//\//_}_${DATE_SHORT}.md"
fi

echo "Generating insights for $REPO..."

# === FETCH DATA ===
echo "  Fetching repo metadata..."
REPO_DATA=$(gh_api "repos/$REPO")

# Validate repo metadata — if this fails, everything else is garbage
if [[ "$(safe_jq "$REPO_DATA" '.full_name // empty' '')" == "" ]]; then
    echo "Error: Could not fetch repo data for '$REPO'. Check that the repo exists and you have access."
    verbose "Response: $REPO_DATA"
    exit 1
fi

echo "  Fetching traffic data..."
CLONES=$(gh_api "repos/$REPO/traffic/clones")
VIEWS=$(gh_api "repos/$REPO/traffic/views")
REFERRERS=$(gh_api "repos/$REPO/traffic/popular/referrers" "[]")
PATHS=$(gh_api "repos/$REPO/traffic/popular/paths" "[]")

echo "  Fetching community data..."
if [[ "$ALL_TIME" == true ]]; then
    echo "  Fetching ALL releases..."
    RELEASES=$(gh_api_all "repos/$REPO/releases?per_page=100" "[]")
    echo "  Fetching ALL contributors..."
    CONTRIBUTORS=$(gh_api_all "repos/$REPO/contributors?per_page=100" "[]")
else
    RELEASES=$(gh_api "repos/$REPO/releases?per_page=10" "[]")
    CONTRIBUTORS=$(gh_api "repos/$REPO/contributors?per_page=100" "[]")
fi

echo "  Fetching issue/PR activity..."
if [[ "$ALL_TIME" == true ]]; then
    echo "  Fetching ALL issues (this may take a while for large repos)..."
    ISSUES_DATA=$(gh_api_all "repos/$REPO/issues?state=all&per_page=100&sort=created&direction=desc" "[]")
    echo "  Fetching ALL pull requests..."
    PRS_DATA=$(gh_api_all "repos/$REPO/pulls?state=all&per_page=100&sort=created&direction=desc" "[]")
else
    ISSUES_DATA=$(gh_api "repos/$REPO/issues?state=all&per_page=30&sort=created&direction=desc" "[]")
    PRS_DATA=$(gh_api "repos/$REPO/pulls?state=all&per_page=30&sort=created&direction=desc" "[]")
fi

# === EXTRACT METRICS ===
# Repo basics
REPO_NAME=$(safe_jq "$REPO_DATA" '.full_name' 'unknown')
DESCRIPTION=$(safe_jq "$REPO_DATA" '.description // "N/A"' 'N/A')
REPO_URL=$(safe_jq "$REPO_DATA" '.html_url' "https://github.com/$REPO")
STARS=$(safe_jq "$REPO_DATA" '.stargazers_count' '0')
FORKS=$(safe_jq "$REPO_DATA" '.forks_count' '0')
WATCHERS=$(safe_jq "$REPO_DATA" '.subscribers_count' '0')
OPEN_ISSUES=$(safe_jq "$REPO_DATA" '.open_issues_count' '0')
CREATED=$(safe_jq "$REPO_DATA" '.created_at // "N/A"' 'N/A')
PUSHED=$(safe_jq "$REPO_DATA" '.pushed_at // "N/A"' 'N/A')
LICENSE=$(safe_jq "$REPO_DATA" '.license.spdx_id // "N/A"' 'N/A')
LANGUAGE=$(safe_jq "$REPO_DATA" '.language // "N/A"' 'N/A')
SIZE_KB=$(safe_jq "$REPO_DATA" '.size' '0')

# Traffic (last 14 days)
CLONE_TOTAL=$(safe_jq "$CLONES" '.count' '0')
CLONE_UNIQUE=$(safe_jq "$CLONES" '.uniques' '0')
VIEW_TOTAL=$(safe_jq "$VIEWS" '.count' '0')
VIEW_UNIQUE=$(safe_jq "$VIEWS" '.uniques' '0')

# Contributors
CONTRIBUTOR_COUNT=$(echo "$CONTRIBUTORS" | jq 'length' 2>/dev/null || echo "0")

# Releases
RELEASE_COUNT=$(echo "$RELEASES" | jq 'length' 2>/dev/null || echo "0")
LATEST_RELEASE=$(echo "$RELEASES" | jq -r '.[0].tag_name // "none"' 2>/dev/null || echo "none")
LATEST_RELEASE_DATE=$(echo "$RELEASES" | jq -r '.[0].published_at // "N/A"' 2>/dev/null || echo "N/A")
RELEASE_DOWNLOADS=$(echo "$RELEASES" | jq '[.[].assets[].download_count] | add // 0' 2>/dev/null || echo "0")

# Commit count — sum contributions from contributors API (reliable, already fetched)
COMMIT_TOTAL=$(echo "$CONTRIBUTORS" | jq '[.[].contributions] | add // 0' 2>/dev/null || echo "0")
if [[ "$COMMIT_TOTAL" == "0" ]]; then
    # Fallback: try git rev-list if we're in the repo locally
    COMMIT_TOTAL=$(git rev-list --count HEAD 2>/dev/null || echo "?")
fi
verbose "Commit total: $COMMIT_TOTAL"

# Activity
ISSUE_COUNT=$(echo "$ISSUES_DATA" | jq '[.[] | select(.pull_request == null)] | length' 2>/dev/null || echo "0")
PR_COUNT=$(echo "$PRS_DATA" | jq 'length' 2>/dev/null || echo "0")
MERGED_PRS=$(echo "$PRS_DATA" | jq '[.[] | select(.merged_at != null)] | length' 2>/dev/null || echo "0")
if [[ "$ALL_TIME" == true ]]; then
    OPEN_ISSUES_COUNTED=$(echo "$ISSUES_DATA" | jq '[.[] | select(.pull_request == null and .state == "open")] | length' 2>/dev/null || echo "0")
    CLOSED_ISSUES=$(echo "$ISSUES_DATA" | jq '[.[] | select(.pull_request == null and .state == "closed")] | length' 2>/dev/null || echo "0")
    OPEN_PRS=$(echo "$PRS_DATA" | jq '[.[] | select(.state == "open")] | length' 2>/dev/null || echo "0")
fi

# === PyPI / npm stats ===
echo "  Checking package registries..."
PYPI_VERSION=""
NPM_VERSION=""

PKG_NAME=$(safe_jq "$REPO_DATA" '.name' '')
PKG_NAME_ENCODED=$(urlencode "$PKG_NAME")

# Try PyPI — validate ownership via project URL
PYPI_DATA=$(curl -sf "https://pypi.org/pypi/$PKG_NAME_ENCODED/json" 2>/dev/null || echo "")
if [[ -n "$PYPI_DATA" ]]; then
    # Check if the package links back to this GitHub repo
    PYPI_HOME=$(echo "$PYPI_DATA" | jq -r '(.info.home_page // ""), (.info.project_urls // {} | to_entries[].value)' 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "")
    REPO_LOWER=$(echo "$REPO" | tr '[:upper:]' '[:lower:]')
    if echo "$PYPI_HOME" | grep -q "github.com/$REPO_LOWER"; then
        verbose "PyPI package '$PKG_NAME' verified — links to $REPO"
        PYPI_VERSION=$(echo "$PYPI_DATA" | jq -r '.info.version // "N/A"' 2>/dev/null || echo "N/A")
        PYPI_STATS=$(curl -sf "https://pypistats.org/api/packages/$PKG_NAME_ENCODED/recent" 2>/dev/null || echo "")
        if [[ -n "$PYPI_STATS" ]]; then
            PYPI_DOWNLOADS_MONTH=$(echo "$PYPI_STATS" | jq -r '.data.last_month // 0' 2>/dev/null || echo "0")
            PYPI_DOWNLOADS_WEEK=$(echo "$PYPI_STATS" | jq -r '.data.last_week // 0' 2>/dev/null || echo "0")
            PYPI_DOWNLOADS_DAY=$(echo "$PYPI_STATS" | jq -r '.data.last_day // 0' 2>/dev/null || echo "0")
        fi
        if [[ "$ALL_TIME" == true ]]; then
            verbose "Fetching PyPI overall downloads..."
            PYPI_OVERALL=$(curl -sf "https://pypistats.org/api/packages/$PKG_NAME_ENCODED/overall" 2>/dev/null || echo "")
            if [[ -n "$PYPI_OVERALL" ]]; then
                PYPI_DOWNLOADS_TOTAL=$(echo "$PYPI_OVERALL" | jq '[.data[] | select(.category == "without_mirrors") | .downloads] | add // 0' 2>/dev/null || echo "0")
            fi
        fi
    else
        verbose "PyPI package '$PKG_NAME' exists but does NOT link to $REPO — skipping"
    fi
fi

# Try npm — validate ownership via repository URL
NPM_DATA=$(curl -sf "https://registry.npmjs.org/$PKG_NAME_ENCODED" 2>/dev/null || echo "")
if [[ -n "$NPM_DATA" ]] && echo "$NPM_DATA" | jq -e '.["dist-tags"]' >/dev/null 2>&1; then
    NPM_REPO_URL=$(echo "$NPM_DATA" | jq -r '.repository.url // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "")
    NPM_HOME=$(echo "$NPM_DATA" | jq -r '.homepage // ""' 2>/dev/null | tr '[:upper:]' '[:lower:]' || echo "")
    REPO_LOWER=$(echo "$REPO" | tr '[:upper:]' '[:lower:]')
    if echo "$NPM_REPO_URL $NPM_HOME" | grep -q "github.com/$REPO_LOWER"; then
        verbose "npm package '$PKG_NAME' verified — links to $REPO"
        NPM_VERSION=$(echo "$NPM_DATA" | jq -r '.["dist-tags"].latest // "N/A"' 2>/dev/null || echo "N/A")
        NPM_DL_WEEK=$(curl -sf "https://api.npmjs.org/downloads/point/last-week/$PKG_NAME_ENCODED" 2>/dev/null || echo "")
        NPM_DL_MONTH=$(curl -sf "https://api.npmjs.org/downloads/point/last-month/$PKG_NAME_ENCODED" 2>/dev/null || echo "")
        if [[ -n "$NPM_DL_WEEK" ]]; then
            NPM_DOWNLOADS_WEEK=$(echo "$NPM_DL_WEEK" | jq -r '.downloads // 0' 2>/dev/null || echo "0")
        fi
        if [[ -n "$NPM_DL_MONTH" ]]; then
            NPM_DOWNLOADS_MONTH=$(echo "$NPM_DL_MONTH" | jq -r '.downloads // 0' 2>/dev/null || echo "0")
        fi
        if [[ "$ALL_TIME" == true ]]; then
            verbose "Fetching npm all-time downloads..."
            NPM_DOWNLOADS_TOTAL=0
            NPM_START=$(echo "$CREATED" | cut -dT -f1)
            NPM_END=$(date -u +"%Y-%m-%d")
            CHUNK_START="$NPM_START"
            while [[ "$CHUNK_START" < "$NPM_END" ]]; do
                if date -v+365d >/dev/null 2>&1; then
                    CHUNK_END=$(date -j -v+365d -f "%Y-%m-%d" "$CHUNK_START" +"%Y-%m-%d" 2>/dev/null || echo "$NPM_END")
                else
                    CHUNK_END=$(date -d "$CHUNK_START + 365 days" +"%Y-%m-%d" 2>/dev/null || echo "$NPM_END")
                fi
                [[ "$CHUNK_END" > "$NPM_END" ]] && CHUNK_END="$NPM_END"
                CHUNK_RESULT=$(curl -sf "https://api.npmjs.org/downloads/point/$CHUNK_START:$CHUNK_END/$PKG_NAME_ENCODED" 2>/dev/null || echo "")
                CHUNK_DL=$(echo "$CHUNK_RESULT" | jq -r '.downloads // 0' 2>/dev/null || echo "0")
                NPM_DOWNLOADS_TOTAL=$((NPM_DOWNLOADS_TOTAL + CHUNK_DL))
                verbose "npm downloads $CHUNK_START:$CHUNK_END → $CHUNK_DL"
                if date -v+1d >/dev/null 2>&1; then
                    CHUNK_START=$(date -j -v+1d -f "%Y-%m-%d" "$CHUNK_END" +"%Y-%m-%d" 2>/dev/null || break)
                else
                    CHUNK_START=$(date -d "$CHUNK_END + 1 day" +"%Y-%m-%d" 2>/dev/null || break)
                fi
            done
        fi
    else
        verbose "npm package '$PKG_NAME' exists but does NOT link to $REPO — skipping"
    fi
fi

# === GENERATE REPORT ===
echo "  Writing report..."

if [[ "$ALL_TIME" == true ]]; then
    PERIOD_LABEL="All Time"
else
    PERIOD_LABEL="Recent"
fi

cat > "$OUTPUT_FILE" << HEADER
# $REPO_NAME

> **$DESCRIPTION**

| | |
|---|---|
| **Report generated** | $DATE_NOW |
| **Repository** | [$REPO_NAME]($REPO_URL) |
| **Time period** | $PERIOD_LABEL |

**$LANGUAGE** | $LICENSE | ${SIZE_KB} KB | Created $(echo "$CREATED" | cut -dT -f1) | Last push $(echo "$PUSHED" | cut -dT -f1)

---

## Key Metrics

| Stars | Forks | Watchers | Contributors | Open Issues | Total Commits |
|:-----:|:-----:|:--------:|:------------:|:-----------:|:-------------:|
| **$STARS** | **$FORKS** | **$WATCHERS** | **$CONTRIBUTOR_COUNT** | **$OPEN_ISSUES** | **$COMMIT_TOTAL** |

---

## Traffic — Last 14 Days

> GitHub traffic data represents **real visitors** (de-duplicated, not bots or mirrors). Unique cloners is the most reliable proxy for real users.

|  | Total | Unique |
|--|------:|-------:|
| Page Views | $VIEW_TOTAL | **$VIEW_UNIQUE** |
| Clones | $CLONE_TOTAL | **$CLONE_UNIQUE** |

<details>
<summary>Daily Clones</summary>

| Date | Clones | Unique |
|------|-------:|-------:|
HEADER

# Clone daily breakdown
echo "$CLONES" | jq -r '.clones[]? | "| \(.timestamp | split("T")[0]) | \(.count) | \(.uniques) |"' >> "$OUTPUT_FILE" 2>/dev/null || echo "| — | — | — |" >> "$OUTPUT_FILE"

cat >> "$OUTPUT_FILE" << 'SECTION'

</details>

<details>
<summary>Daily Views</summary>

| Date | Views | Unique |
|------|------:|-------:|
SECTION

# View daily breakdown
echo "$VIEWS" | jq -r '.views[]? | "| \(.timestamp | split("T")[0]) | \(.count) | \(.uniques) |"' >> "$OUTPUT_FILE" 2>/dev/null || echo "| — | — | — |" >> "$OUTPUT_FILE"

echo "" >> "$OUTPUT_FILE"
echo "</details>" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

if [[ "$ALL_TIME" == true ]]; then
    echo "> **Note:** GitHub traffic API is limited to the last 14 days regardless of report mode. This is a GitHub platform limitation." >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

# === REFERRERS ===
{
    REF_LINES=$(echo "$REFERRERS" | jq -r '.[]? | "| \(.referrer) | \(.count) | \(.uniques) |"' 2>/dev/null || echo "")
    if [[ -n "$REF_LINES" ]]; then
        echo "### Top Referrers"
        echo ""
        echo "| Source | Views | Unique |"
        echo "|--------|------:|-------:|"
        echo "$REF_LINES"
        echo ""
    fi
} >> "$OUTPUT_FILE"

# === POPULAR CONTENT ===
{
    PATH_LINES=$(echo "$PATHS" | jq -r '.[]? | "| \(.path) | \(.count) | \(.uniques) |"' 2>/dev/null || echo "")
    if [[ -n "$PATH_LINES" ]]; then
        echo "### Popular Content"
        echo ""
        echo "| Path | Views | Unique |"
        echo "|------|------:|-------:|"
        echo "$PATH_LINES"
        echo ""
    fi
} >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# === REAL USERS VS BOTS — CONCISE ===
{
    echo "## Real Users vs Bots"
    echo ""
    echo "| Signal | Value | Confidence |"
    echo "|--------|------:|:----------:|"
    echo "| Unique cloners (14d) | **$CLONE_UNIQUE** | \`HIGH\` |"
    echo "| Unique visitors (14d) | **$VIEW_UNIQUE** | \`HIGH\` |"
    echo "| Stars | **$STARS** | \`HIGH\` |"
    echo "| Forks | **$FORKS** | \`MED\` |"
    if [[ -n "${PYPI_DOWNLOADS_MONTH:-}" ]]; then
        echo "| PyPI downloads/month | $PYPI_DOWNLOADS_MONTH | \`LOW\` |"
    fi
    if [[ -n "${NPM_DOWNLOADS_MONTH:-}" ]]; then
        echo "| npm downloads/month | $NPM_DOWNLOADS_MONTH | \`LOW\` |"
    fi
    echo ""
    echo "> **Estimated real users: ~$CLONE_UNIQUE** (unique cloners). Stars ($STARS) confirm genuine interest. Registry downloads are inflated by bots/CI/mirrors."
    echo ""
} >> "$OUTPUT_FILE"

# === PACKAGE REGISTRY STATS ===
{
    if [[ -n "$PYPI_VERSION" ]] || [[ -n "$NPM_VERSION" ]]; then
        echo "---"
        echo ""
        echo "## Package Downloads"
        echo ""
        echo "> Registry counts include bots, CI, mirrors. Real users ~10-20% of these numbers."
        echo ""
        if [[ -n "$PYPI_VERSION" ]] && [[ -n "$NPM_VERSION" ]]; then
            echo "| | PyPI | npm |"
            echo "|--|-----:|----:|"
            echo "| Version | \`$PYPI_VERSION\` | \`$NPM_VERSION\` |"
            echo "| Last day | ${PYPI_DOWNLOADS_DAY:-—} | — |"
            echo "| Last week | ${PYPI_DOWNLOADS_WEEK:-—} | ${NPM_DOWNLOADS_WEEK:-—} |"
            echo "| Last month | ${PYPI_DOWNLOADS_MONTH:-—} | ${NPM_DOWNLOADS_MONTH:-—} |"
            if [[ "$ALL_TIME" == true ]]; then
                echo "| **Total** | **${PYPI_DOWNLOADS_TOTAL:-—}** | **${NPM_DOWNLOADS_TOTAL:-—}** |"
            fi
        elif [[ -n "$PYPI_VERSION" ]]; then
            if [[ "$ALL_TIME" == true ]]; then
                echo "| PyPI | Version | Day | Week | Month | Total |"
                echo "|------|---------|----:|-----:|------:|------:|"
                echo "| [pypi.org/project/$PKG_NAME](https://pypi.org/project/$PKG_NAME/) | \`$PYPI_VERSION\` | ${PYPI_DOWNLOADS_DAY:-—} | ${PYPI_DOWNLOADS_WEEK:-—} | ${PYPI_DOWNLOADS_MONTH:-—} | **${PYPI_DOWNLOADS_TOTAL:-—}** |"
            else
                echo "| PyPI | Version | Day | Week | Month |"
                echo "|------|---------|----:|-----:|------:|"
                echo "| [pypi.org/project/$PKG_NAME](https://pypi.org/project/$PKG_NAME/) | \`$PYPI_VERSION\` | ${PYPI_DOWNLOADS_DAY:-—} | ${PYPI_DOWNLOADS_WEEK:-—} | ${PYPI_DOWNLOADS_MONTH:-—} |"
            fi
        elif [[ -n "$NPM_VERSION" ]]; then
            if [[ "$ALL_TIME" == true ]]; then
                echo "| npm | Version | Week | Month | Total |"
                echo "|-----|---------|-----:|------:|------:|"
                echo "| [npmjs.com/package/$PKG_NAME](https://www.npmjs.com/package/$PKG_NAME) | \`$NPM_VERSION\` | ${NPM_DOWNLOADS_WEEK:-—} | ${NPM_DOWNLOADS_MONTH:-—} | **${NPM_DOWNLOADS_TOTAL:-—}** |"
            else
                echo "| npm | Version | Week | Month |"
                echo "|-----|---------|-----:|------:|"
                echo "| [npmjs.com/package/$PKG_NAME](https://www.npmjs.com/package/$PKG_NAME) | \`$NPM_VERSION\` | ${NPM_DOWNLOADS_WEEK:-—} | ${NPM_DOWNLOADS_MONTH:-—} |"
            fi
        fi
        if [[ "$ALL_TIME" == true ]]; then
            echo ""
            echo "> PyPI total covers ~180 days (pypistats.org data retention). npm total covers the full package lifetime."
        fi
        echo ""
    fi
} >> "$OUTPUT_FILE"

echo "---" >> "$OUTPUT_FILE"
echo "" >> "$OUTPUT_FILE"

# === ACTIVITY & CONTRIBUTORS — COMPACT ===
{
    echo "## Activity & Contributors"
    echo ""
    if [[ "$ALL_TIME" == true ]]; then
        echo "### Issues & PRs — All Time"
        echo ""
        echo "| | Open | Closed/Merged | Total |"
        echo "|--|-----:|------:|------:|"
        echo "| Issues | $OPEN_ISSUES_COUNTED | $CLOSED_ISSUES | $ISSUE_COUNT |"
        echo "| PRs | $OPEN_PRS | $MERGED_PRS merged | $PR_COUNT |"
    else
        echo "### Issues & PRs — Last 30 Days"
        echo ""
        echo "| Issues | PRs | Merged |"
        echo "|:------:|:---:|:------:|"
        echo "| $ISSUE_COUNT | $PR_COUNT | $MERGED_PRS |"
    fi
    echo ""

    if [[ "$RELEASE_COUNT" -gt 0 ]]; then
        echo "### Releases"
        echo ""
        echo "| Tag | Date | Downloads |"
        echo "|-----|------|----------:|"
        if [[ "$ALL_TIME" == true ]]; then
            echo "$RELEASES" | jq -r '.[]? | "| \(.tag_name) | \(.published_at | split("T")[0]) | \([.assets[]?.download_count] | add // 0) |"' 2>/dev/null || true
            echo ""
            echo "> All $RELEASE_COUNT releases shown. Total asset downloads: $RELEASE_DOWNLOADS"
        else
            echo "$RELEASES" | jq -r '.[0:5][]? | "| \(.tag_name) | \(.published_at | split("T")[0]) | \([.assets[]?.download_count] | add // 0) |"' 2>/dev/null || true
            echo ""
            if [[ "$RELEASE_COUNT" -gt 5 ]]; then
                echo "> Showing latest 5 of $RELEASE_COUNT releases. Total asset downloads: $RELEASE_DOWNLOADS"
            fi
        fi
        echo ""
    else
        echo "### Releases"
        echo ""
        echo "No releases yet."
        echo ""
    fi

    if [[ "$ALL_TIME" == true ]]; then
        SHOW_TOP=25
        echo "### Top Contributors (all $CONTRIBUTOR_COUNT)"
    else
        SHOW_TOP=10
        echo "### Top Contributors"
    fi
    echo ""
    echo "| # | Contributor | Commits |"
    echo "|--:|------------|--------:|"
    echo "$CONTRIBUTORS" | jq -r "to_entries | .[:$SHOW_TOP][] | \"| \(.key + 1) | [@\(.value.login)](https://github.com/\(.value.login)) | \(.value.contributions) |\"" 2>/dev/null || echo "| — | No data | — |"
    echo ""
} >> "$OUTPUT_FILE"

# === FOOTER ===
{
    echo "---"
    echo ""
    echo "<sub>Generated by [repo-insights](https://github.com/luongnv89/repo-insights) on $DATE_NOW</sub>"
} >> "$OUTPUT_FILE"

echo ""
echo "Done! Report written to: $OUTPUT_FILE"
echo ""
echo "Quick summary:"
if [[ "$ALL_TIME" == true ]]; then
    echo "  Mode: ALL TIME"
fi
echo "  Stars: $STARS | Forks: $FORKS | Contributors: $CONTRIBUTOR_COUNT"
echo "  Unique cloners (14d): $CLONE_UNIQUE | Unique visitors (14d): $VIEW_UNIQUE"
if [[ "$ALL_TIME" == true ]]; then
    echo "  Total issues: $ISSUE_COUNT | Total PRs: $PR_COUNT | Merged: $MERGED_PRS"
    echo "  Total releases: $RELEASE_COUNT | Total contributors: $CONTRIBUTOR_COUNT"
fi
if [[ -n "$PYPI_VERSION" ]]; then
    if [[ "$ALL_TIME" == true ]]; then
        echo "  PyPI: v$PYPI_VERSION (${PYPI_DOWNLOADS_MONTH:-?}/month, ${PYPI_DOWNLOADS_TOTAL:-?} total)"
    else
        echo "  PyPI: v$PYPI_VERSION (${PYPI_DOWNLOADS_MONTH:-?} downloads/month)"
    fi
fi
if [[ -n "$NPM_VERSION" ]]; then
    if [[ "$ALL_TIME" == true ]]; then
        echo "  npm: v$NPM_VERSION (${NPM_DOWNLOADS_MONTH:-?}/month, ${NPM_DOWNLOADS_TOTAL:-?} total)"
    else
        echo "  npm: v$NPM_VERSION (${NPM_DOWNLOADS_MONTH:-?} downloads/month)"
    fi
fi
