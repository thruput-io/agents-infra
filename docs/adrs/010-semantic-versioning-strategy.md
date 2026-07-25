# 10. Semantic Versioning Strategy & Release Lifecycle

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
Downstream FAST stages depend on stable, predictable module versions. Ad-hoc breaking changes or unclear version tags can break infrastructure deployments. A standardized versioning strategy is necessary to communicate changes clearly.

## Decision
1. **Semantic Versioning Specification**: All module releases **MUST** strictly follow Semantic Versioning 2.0.0 (`MAJOR.MINOR.PATCH`):
   - `MAJOR` version bump: Breaking changes (e.g. removing required variables, renaming outputs, or changing resource definitions that force resource recreation).
   - `MINOR` version bump: New backward-compatible functionality (e.g. adding optional variables or new outputs).
   - `PATCH` version bump: Backward-compatible bug fixes or documentation updates.
2. **Immutable Git Tagging**: Every release **MUST** be published as an immutable Git tag prefixed with `v` (e.g. `v1.0.0`).
3. **Changelog Maintenance**: All releases **MUST** document changes in a `CHANGELOG.md` file following Keep a Changelog standards.

## References
* [Semantic Versioning 2.0.0 Specification](https://semver.org)

## Consequences
* **Predictable Upgrades**: Downstream FAST projects can safely upgrade `MINOR` and `PATCH` versions without risking breaking infrastructure changes.
* **Traceable History**: Annotated git tags and changelogs provide clear auditability of module evolution over time.
