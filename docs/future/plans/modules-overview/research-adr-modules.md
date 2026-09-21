# ADR & Runtime Capabilities to Module Mapping Research

## Executive Summary
This research analyzes the 10 Architectural Decision Records (`docs/adrs/001-*.md` through `010-*.md`) and key agent runtime capabilities (such as hosting Model Context Protocol - MCP servers) to map all required Terraform modules.

---

## ADR Requirements Analysis

| ADR / Capability | Title | Key Architectural Requirements | Implied / Explicit Terraform Modules |
| :--- | :--- | :--- | :--- |
| **ADR-001** | Pure Terraform Provider Project | Stateless, pure resource modules consumed by FAST stages without backend blocks. | All modules must be standalone submodules. |
| **ADR-002** | Ephemeral Integration Testing | Test harness for ephemeral GCP sandbox provisioning and teardown. | Integration test runner setup. |
| **ADR-003** | Public Repo & GitHub Distribution | GitHub distribution standards and public visibility. | Governance & distribution structure. |
| **ADR-004** | FAST Stage Integration Pattern | Standardized contract interfaces (project IDs, SAs, secrets) for FAST stages. | All modules conform to FAST contract interfaces. |
| **ADR-005** | Modular Design & Separation | Single-responsibility submodules under `modules/`. Explicitly lists `agent-identity`, `secret-access`, `resource-tagging`. | `modules/agent-identity`<br>`modules/secret-access`<br>`modules/resource-tagging` |
| **ADR-006** | Compliance Framework | Security hooks, Conftest policy-as-code, Secret Manager references. | Pre-push and CI policy enforcement. |
| **ADR-007** | Dependency & Provider Versioning | Pinned provider versions in `versions.tf` (`required_version >= 1.5.0`). | Applies to all submodules. |
| **ADR-008** | Secret Management | GCP Secret Manager secrets (`google_secret_manager_secret`) and least-privilege IAM bindings (`roles/secretmanager.secretAccessor`). | `modules/secret-access` |
| **ADR-009** | Automated CI/CD Pipeline | Automated linting, static analysis, policy verification, integration tests. | CI workflow definitions. |
| **ADR-010** | Semantic Versioning Strategy | SemVer 2.0.0 and immutable git tags. | Release lifecycle governance. |
| **MCP Server Runtime** | Model Context Protocol Runtime | Serverless compute (Cloud Run / GKE), IAM invoker roles (`roles/run.invoker`), Workload Identity, and Secret Manager environment integration for MCP tools. | `modules/mcp-server` |

---

## Complete Module Mapping Proposal

1. **`modules/access-group`**:
   - Provisions GCP User Groups and IAM role assignments matching FAST conventions.
2. **`modules/agent-identity`** (Service Accounts):
   - Provisions agent service account, descriptive labels (`agent-call-name`, `agent-human-owner`), and tag bindings.
3. **`modules/agent-github-app`**:
   - Manages GitHub App installation on target repositories and sets repo-level permissions via `integrations/github`.
4. **`modules/secret-access`** (Secret Management):
   - Provisions GCP Secret Manager secrets/versions and grants least-privilege `roles/secretmanager.secretAccessor` bindings to agent service accounts (ADR-008).
5. **`modules/resource-tagging`**:
   - Manages Resource Manager tag keys, tag values, and tag bindings for agent classification (`agent-type`) (ADR-005).
6. **`modules/agent-mailbox`**:
   - Provisions singleton agent mail account aliases (`<call-name>@thruput.com`).
7. **`modules/mcp-server`**:
   - Provisions Cloud Run serverless compute, invoker IAM bindings (`roles/run.invoker`), and runtime environment configurations for Model Context Protocol (MCP) server endpoints.
