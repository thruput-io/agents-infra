# Agents Infrastructure

Google Cloud FAST Infrastructure and Module Repository for AI Agent Service Management.

---

## Overview

This repository defines the foundational infrastructure modules, access control models, identity boundaries, secret management patterns, and CI/CD pipelines required to deploy and manage AI agent execution environments within Google Cloud FAST.

---

## Architectural Decision Records (ADRs)

Architectural decisions are formally recorded as immutable ADRs under [`docs/adrs/`](docs/adrs/):

- [ADR-001: Pure Terraform Provider Project](docs/adrs/001-pure-terraform-provider-project.md)
- [ADR-002: Ephemeral Integration Testing & Teardown](docs/adrs/002-ephemeral-integration-testing.md)
- [ADR-003: Public Repo and GitHub Distribution](docs/adrs/003-public-repo-and-github-distribution.md)
- [ADR-004: FAST Stage Integration Pattern](docs/adrs/004-fast-stage-integration-pattern.md)
- [ADR-005: Modular Design & Separation of Responsibilities](docs/adrs/005-modular-design.md)
- [ADR-006: Compliance Framework & Pre-Push Security Guardrails](docs/adrs/006-compliance-framework-and-pre-push-security-guardrails.md)
- [ADR-007: Dependency & Provider Version Management](docs/adrs/007-dependency-and-provider-version-management.md)
- [ADR-008: Secret Management & Credentials](docs/adrs/008-secret-management.md)
- [ADR-009: Automated CI/CD Pipeline Integration](docs/adrs/009-automated-cicd-pipeline-integration.md)
- [ADR-010: Semantic Versioning Strategy & Release Lifecycle](docs/adrs/010-semantic-versioning-strategy.md)
- [ADR-011: MCP Server Runtime Architecture & Identity Separation](docs/adrs/011-mcp-server-runtime-architecture.md)
- [ADR-012: Deterministic Infrastructure](docs/adrs/012-deterministic-infrastructure.md)


## Modules & Execution Plan

Module specifications and execution plans are maintained under [`docs/plans/`](docs/plans/):

- [Modules Plan](docs/plans/modules-overview/modules-plan.md)
