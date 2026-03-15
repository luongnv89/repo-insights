# Development Guide

## Prerequisites

| Tool | Install | Verify |
|------|---------|--------|
| [gh](https://cli.github.com/) | `brew install gh` | `gh --version` |
| [jq](https://jqlang.github.io/jq/) | `brew install jq` | `jq --version` |
| [curl](https://curl.se/) | Pre-installed on most systems | `curl --version` |
| git | Pre-installed on most systems | `git --version` |

Authenticate GitHub CLI:
```bash
gh auth login
```

## Running Locally

```bash
# Auto-detect repo from current directory
./repo-insights.sh

# Specific repo
./repo-insights.sh -r owner/repo

# Custom output + verbose
./repo-insights.sh -r owner/repo -o report.md -v
```

## Testing

```bash
# Run all smoke tests
./test.sh

# Syntax check only
bash -n repo-insights.sh
```

## Debugging

Use verbose mode to see API call diagnostics:
```bash
./repo-insights.sh -v -r owner/repo 2>debug.log
```

The debug log shows:
- Each API endpoint called
- Response size in bytes
- Package ownership validation results

## Project Structure

```
repo-insights/
├── repo-insights.sh    # Main script (single file)
├── test.sh             # Smoke test suite
├── README.md           # User-facing documentation
├── CONTRIBUTING.md     # Contributor guide
├── TODOS.md            # Planned future work
├── LICENSE             # MIT
├── .gitignore          # Excludes generated reports
├── assets/logo/        # Brand assets (7 SVG variants)
├── docs/               # Technical documentation
└── .github/            # Issue and PR templates
```

## Adding a New Report Section

1. Fetch data in the **FETCH PHASE** using `gh_api`:
   ```bash
   NEW_DATA=$(gh_api "repos/$REPO/your-endpoint" "[]")
   ```

2. Extract metrics in the **EXTRACT PHASE** using `safe_jq`:
   ```bash
   METRIC=$(safe_jq "$NEW_DATA" '.field' '0')
   ```

3. Add verbose logging:
   ```bash
   verbose "New metric: $METRIC"
   ```

4. Write the section in the **GENERATE PHASE**:
   ```bash
   {
       echo "## New Section"
       echo ""
       echo "| Metric | Value |"
       echo "|--------|------:|"
       echo "| Something | $METRIC |"
       echo ""
   } >> "$OUTPUT_FILE"
   ```

5. Add a test in `test.sh`:
   ```bash
   if grep -q '## New Section' "$OUTPUT" 2>/dev/null; then pass "has New Section"; else fail "has New Section"; fi
   ```

## Adding a New Package Registry

1. Add the API call in the **PyPI / npm stats** section
2. Validate ownership — check that the package's repository URL contains `github.com/$REPO`
3. Add verbose logging for both match and skip cases
4. Include in the report conditionally (only if validated)
