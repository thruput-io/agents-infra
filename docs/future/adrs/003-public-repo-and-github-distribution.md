# 3. Public Repo and GitHub Distribution

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
Downstream FAST stages and Terraform configurations must consume the agent infrastructure modules cleanly and directly without custom registry overhead.

## Decision
1. **Public Repository**: This repository is maintained as a public GitHub repository (`<owner>/agents-infra`).
2. **Direct GitHub Sourcing**: Modules are distributed via direct GitHub source URLs using standard subdirectory syntax (`github.com/<owner>/agents-infra//modules/<module-name>?ref=<tag>`).
3. **Version Pinning**: Downstream FAST configurations **MUST** pin module versions using immutable git tags or commit SHAs (`?ref=vX.Y.Z`).

## References
* [HashiCorp Terraform Module Sources - GitHub](https://developer.hashicorp.com/terraform/language/modules/sources)

## Consequences
* **Zero Custom Registry Overhead**: Downstream FAST projects consume modules natively using built-in Terraform Git sources.
* **Deterministic Versioning**: Explicit tag pinning guarantees stability and prevents unexpected breaking changes in infrastructure deployments.
