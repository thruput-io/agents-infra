# Modules Plan

This document outlines the complete set of single-responsibility Terraform modules under `modules/` required to fulfill Architectural Decision Records ADR-001 through ADR-010 and agent runtime requirements (including MCP server hosting).

---

## Terraform Submodules Taxonomy

### 1. Access Group (`modules/access-group`)
- **Purpose**: Provisions GCP User Groups and FAST IAM role assignments to those groups. Agent service accounts are granted roles exclusively via group membership.
- **ADR References**: [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md)

### 2. Agent Identity (`modules/agent-identity`)
- **Purpose**: Creates GCP Service Accounts with descriptive labels (`agent-call-name`, `agent-human-owner`) and Resource Manager tag bindings (`agent-type`).
- **ADR References**: [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md)

### 3. Agent GitHub App (`modules/agent-github-app`)
- **Purpose**: Configures GitHub App installations and repository-level access using the `integrations/github` provider. Secret PEMs are stored securely in Secret Manager and referenced opaquely.
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)

### 4. Secret Access (`modules/secret-access`)
- **Purpose**: Provisions GCP Secret Manager secrets (`google_secret_manager_secret`) and grants least-privilege `roles/secretmanager.secretAccessor` IAM roles to authorized agent service accounts.
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)

### 5. Resource Tagging (`modules/resource-tagging`)
- **Purpose**: Manages GCP Resource Manager tag keys, tag values (e.g. `agent-type/reviewer`), and tag bindings to enforce identity and security classification across GCP resources.
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md)

### 6. Agent Mailbox (`modules/agent-mailbox`)
- **Purpose**: Provisions singleton Google Workspace/Mail accounts and creates per-agent email aliases (`<call-name>@thruput.com`).
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md)

### 7. MCP Server Runtime (`modules/mcp-server`)
- **Purpose**: Provisions containerized serverless compute (Cloud Run), invoker IAM roles (`roles/run.invoker`), Workload Identity integration, and runtime Secret Manager environment variable injection for Model Context Protocol (MCP) server tools.
- **ADR References**: [ADR-001](../../adrs/001-pure-terraform-provider-project.md), [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)
