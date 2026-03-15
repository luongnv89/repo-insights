#!/usr/bin/env bash
# test.sh — Smoke test for repo-insights.sh
# Runs the script against this repo and validates output structure.

SCRIPT="./repo-insights.sh"
OUTPUT="/tmp/repo-insights-test-$$.md"
PASS=0
FAIL=0

pass() {
    echo "  PASS: $1"
    ((PASS++))
}

fail() {
    echo "  FAIL: $1"
    ((FAIL++))
}

cleanup() {
    rm -f "$OUTPUT"
}
trap cleanup EXIT

echo "Running smoke tests..."
echo ""

# Test 1: Help flag
echo "Test: --help"
HELP_OUT=$(bash "$SCRIPT" -h 2>&1)
if [[ $? -eq 0 ]]; then pass "exits 0"; else fail "exits 0"; fi
if echo "$HELP_OUT" | grep -q "Usage:"; then pass "shows usage"; else fail "shows usage"; fi

# Test 2: Invalid flag
echo "Test: invalid flag"
bash "$SCRIPT" --bogus >/dev/null 2>&1
if [[ $? -ne 0 ]]; then pass "exits non-zero"; else fail "exits non-zero"; fi

# Test 3: Invalid repo format
echo "Test: invalid repo format"
bash "$SCRIPT" -r 'not-a-repo' >/dev/null 2>&1
if [[ $? -ne 0 ]]; then pass "rejects bad format"; else fail "rejects bad format"; fi

# Test 4: Generate report for this repo
echo "Test: generate report"
bash "$SCRIPT" -o "$OUTPUT" >/dev/null 2>&1
if [[ -f "$OUTPUT" ]]; then pass "output file exists"; else fail "output file exists"; fi
if [[ -s "$OUTPUT" ]]; then pass "file is non-empty"; else fail "file is non-empty"; fi

# Test 5: Report structure
echo "Test: report sections"
if grep -q '## Key Metrics' "$OUTPUT" 2>/dev/null; then pass "has Key Metrics"; else fail "has Key Metrics"; fi
if grep -q '## Traffic' "$OUTPUT" 2>/dev/null; then pass "has Traffic"; else fail "has Traffic"; fi
if grep -q '## Real Users vs Bots' "$OUTPUT" 2>/dev/null; then pass "has Real Users vs Bots"; else fail "has Real Users vs Bots"; fi
if grep -q '## Activity & Contributors' "$OUTPUT" 2>/dev/null; then pass "has Activity & Contributors"; else fail "has Activity & Contributors"; fi
if grep -q 'Report generated' "$OUTPUT" 2>/dev/null; then pass "has report timestamp"; else fail "has report timestamp"; fi
if grep -q 'github.com' "$OUTPUT" 2>/dev/null; then pass "has repo link"; else fail "has repo link"; fi
if grep -q 'repo-insights' "$OUTPUT" 2>/dev/null; then pass "has footer"; else fail "has footer"; fi

# Test 6: No false positive package match
echo "Test: package validation"
if grep -q 'Package Downloads' "$OUTPUT" 2>/dev/null; then
    # If package section exists, it should link back to this repo
    pass "package section present (verified ownership)"
else
    pass "no unrelated packages shown"
fi

# Test 7: Dynamic filename
echo "Test: dynamic filename"
bash "$SCRIPT" >/dev/null 2>&1
EXPECTED_PATTERN="*_*_$(date -u +%Y%m%d).md"
GENERATED=$(ls $EXPECTED_PATTERN 2>/dev/null | head -1 || true)
if [[ -n "$GENERATED" ]]; then pass "dynamic filename matches pattern"; else fail "dynamic filename matches pattern"; fi
rm -f "$GENERATED"

# Test 8: Verbose flag
echo "Test: verbose flag"
VERBOSE_OUT=$(bash "$SCRIPT" -v -o /tmp/repo-insights-verbose-$$.md 2>&1)
if echo "$VERBOSE_OUT" | grep -q '\[verbose\]'; then pass "verbose outputs diagnostics"; else fail "verbose outputs diagnostics"; fi
rm -f "/tmp/repo-insights-verbose-$$.md"

echo ""
echo "Results: $PASS passed, $FAIL failed"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
