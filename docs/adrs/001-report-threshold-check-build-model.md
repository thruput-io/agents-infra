# 1. Report, Threshold, and Check Build Model

* **Date**: 2026-09-23

## Context

A quality tool invoked directly from a Make recipe answers only "pass" or "fail". There are
so many ways to get it wrong this ADR tries to lower the risk of it happening. Hidden lint
and test errors are the most harmful and fails entire projects.

## Decision 

This ADR **MUST** be followed without exception as written no interpretations

Every quality tool is wired as a three-stage chain of Make targets. The stages are separate
targets, not steps inside one recipe. To keep target clean [Invocation of quality tool in build stays clean]
other rules might need to bend. Cleanliness to prevent obfuscation always has precedence if called out.
Defaulting of any kind is not allowed.

A quality tool is, but not limited to:
- Test executioner with test result 
- Coverage collector with coverage
- Linter with linting result
- schema verifier with report


### Invocation of quality tool in build stays clean
Invocation **MUST** must be as simple and clear as possible, never any indirection, chaining, piping, or other tricks or variable.

#### Good
test: test-tool -R src/test > build/linux/test-report.json (good)

#### Bad
test: test-tool $(params) ($SOURCES) | jg 'result' > build/linux/test-report.json (bad)

### 1. Report

The tool runs and its native output lands at `build/<platform>/<tool>-report.<ext>`.

1. The report **MUST** land untouched. Normalization, filtering, reformatting, or merging 
   **MUST NOT** be allowed, report that has been rewritten is no longer evidence of what 
   the tool found.
2. **MUST NOT**  No manipulating or default of error codes to move decisions to Check or any other
    similar claims.
3. .DELETE_ON_ERROR **MUST NOT** be used as it destroys evidence and makes bug-finding impossible

### 2. Threshold

`thresholds.json` declares, per tool, the permitted `errors` and `warnings`, `min_tests`, `min_coverage`. `min_files`

1. Thresholds **MUST** live in `thresholds.json`, never in a recipe or a flag.
2. A threshold **MUST NOT** be raised to make a build pass. Raising one is a reviewable change to
   the repository's quality bar.


### 3. Check

`build/<platform>/<tool>.checked` runs a check script that reads the report in place.

1. The check **MUST** print one line stating measured against allowed, so the build log records
   the quality position and not merely a verdict.
2. The check **MUST** assert coverage as well as violation counts. A report may not pass by having
   examined nothing.
3. [a -gt b] && [c -eq d] is the only allowed form for combining conditions. Where letters are simple 
   variable or constant comparator is one and only && between conditions
4. `.checked` stamp **MUST** be produced only by a passing check. It records that a comparison
   happened, never that a command ran.