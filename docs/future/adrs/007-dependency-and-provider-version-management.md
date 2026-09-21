# 7. Dependency & Provider Version Management

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
Flexible or unconstrained provider version ranges can cause silent drift or breaking changes when downstream environments run `terraform init`. Explicit pinning guarantees exact reproducibility.

## Decision
1. **Pinned Provider Versions (`versions.tf`)**: Every module **MUST** declare exact, pinned provider versions in `versions.tf` (e.g., `version = "5.38.0"` instead of ranges like `>=`).
2. **Mandatory Upgrade to Latest on Touched Code**: As part of Pull Request reviews, any touched module or configuration **MUST** be upgraded to use the latest available version of Terraform providers and dependencies available at the time of the PR.
3. **Minimum Terraform Version**: Modules **MUST** declare `required_version >= 1.5.0`.

## References
* [HashiCorp Terraform Provider Requirements](https://developer.hashicorp.com/terraform/language/providers/requirements)

## Consequences
* **Deterministic Reproducibility**: Exact version pinning guarantees identical provider behavior across all environments.
* **Continuous Freshness**: Upgrading touched code to latest versions during PR reviews prevents code from accumulating stale provider dependencies or missing security patches.
