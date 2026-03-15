# Future Work

## P2: JSON output format
Add `--format json` flag for structured output. Enables programmatic consumption, CI integration, and reliable trend comparison. All data is already in shell variables — writing JSON is straightforward with jq. Unblocks trend comparison below.
**Effort:** M

## P2: Trend comparison across reports
Add `--compare old.md new.md` or a companion script that diffs two report snapshots and shows deltas (stars +5, cloners -2). Dynamic filenames create natural history but no way to see trends. May need JSON output first for reliable parsing.
**Effort:** L

## P3: Parallel API fetching
Run independent `gh api` and `curl` calls concurrently with bash background jobs. Cuts runtime from ~5s to ~1.5s. Adds ~20 lines complexity with temp files or process substitution.
**Effort:** M
