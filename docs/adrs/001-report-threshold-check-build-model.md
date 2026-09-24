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
test: test-tool $(params) ($SOURCES) | jg 'result' > build/test-module/test-report.json (bad)

### 1. Report

The tool runs and its native output lands at `build/<platform>/<tool>-report.<ext>`.

1. The report **MUST** land untouched. Normalization, filtering, reformatting, or merging
   **MUST NOT** be allowed, report that has been rewritten is no longer evidence of what
   the tool found.
2. An exit code **MUST NOT** be defaulted or rewritten. A tool that exits non-zero because it
   found something still leaves its report on disk, but the recipe **MUST** be left to fail on
   that exit code: the build stops right there, with the tool's own output, instead of carrying
   on to a check stage that would only repeat the verdict.
3. .DELETE_ON_ERROR **MUST NOT** be used as it destroys evidence and makes bug-finding impossible
4. Before any report is generated, every tool a check depends on **MUST** be proven to run, not
   merely found on `PATH`: `build/versions.txt` asks each one for its version, so a missing or
   broken install fails the build immediately, before an empty report could be mistaken for a
   clean run.

### 2. Threshold

Threshold constants are hardcoded directly inside each target's `.checked` check recipe where they are evaluated.

1. Threshold values (e.g. max 0 lint errors, min 10 tests, floor 22% bash coverage) **MUST** be explicitly written directly in the check assertion recipe.
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
4. `.checked` **MUST** produce no file. The comparison is cheap, so it runs every time; the
   targets **MUST** be phony.