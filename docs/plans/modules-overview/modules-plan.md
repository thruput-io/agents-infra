# Modules Plan & Terraform Interface Contracts

This document defines the complete set of single-responsibility Terraform submodules under `modules/`, detailing their FAST stage alignment, architectural decisions, input contracts, and output contracts to ensure seamless integration into Google Cloud FAST.

---

## Global Architectural Directives (ADR-003 Parity)

All submodules in this project strictly comply with **[google-dev ADR 003](../../../google-dev/docs/adr/003-strict-environment-parity.md)** and repository governance rules:

1. **Zero Conditional Branching**: Submodules are linear, declarative units. They contain zero conditional branching (`count = var.enable ? 1 : 0`) or internal environment logic.
2. **Explicit Variable Injection**: All required variables must be explicitly provided by the caller. Internal shell or fallback magic is prohibited.
3. **Out-of-Band Secret Lifecycle**: Plaintext secret payloads are never committed to Terraform state. Secret shells and IAM accessor bindings are managed by IaC; secret versions are populated out-of-band via Secret Manager.
4. **Strict Identity Separation**: Invoking agent identities, MCP runtime identities, and management identities are strictly separate service accounts following least-privilege principles.

---

## Terraform Submodules Taxonomy & Interface Contracts

### 1. Access Group (`modules/access-group`)
- **FAST Stage Alignment**: Stage 1 (Resource Manager) / Stage 3 (Tenant/Project Factory)
- **Purpose**: Provisions GCP User Groups and FAST IAM role assignments to those groups. Agent service accounts are granted roles exclusively via group membership.
- **Naming Enforced**: Cloud Identity group emails strictly enforce the FAST convention `${prefix}-${group_key}@${domain}` (e.g. `fast-agent-reviewer@thruput.com`).
- **Inputs**:
  - `organization_id` (`string`, required): GCP Organization ID where groups reside.
  - `domain` (`string`, required): Primary domain name for Cloud Identity groups (e.g., `thruput.com`).
  - `prefix` (`string`, required): Mandatory FAST group naming prefix (e.g., `"fast-agent"`).
  - `group_definitions` (`map(object({ display_name = string, description = string }))`, required): Map of group keys to group metadata.
  - `group_iam_roles` (`map(list(string))`, optional, default `{}`): Map of group keys to lists of GCP IAM role names.
- **Outputs**:
  - `group_emails` (`map(string)`): Map of group keys to generated Cloud Identity group email addresses (`${prefix}-${group_key}@${domain}`).
  - `group_ids` (`map(string)`): Map of group keys to Cloud Identity group IDs.
  - `iam_bindings` (`map(list(string))`): Applied IAM role bindings per group key.
- **ADR References**: [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md)

---

### 2. Agent Identity (`modules/agent-identity`)
- **FAST Stage Alignment**: Stage 3 (Project Factory / Tenant Project)
- **Purpose**: Creates GCP Service Accounts with descriptive labels (`agent-call-name`, `agent-human-owner`) and **GitHub Workload Identity Federation (WIF)** bindings for zero-secret CI/CD & event publishing.
- **Single Responsibility**: Manages SA identity and WIF impersonation bindings exclusively. Resource Manager tag bindings are cleanly delegated to `modules/resource-tagging/binding`.
- **Zero-Secret WIF**: Integrates directly with FAST Stage 0 Workload Identity Pools (`projects/*/locations/global/workloadIdentityPools/github-pool`) to bind `roles/iam.workloadIdentityUser` and `roles/pubsub.publisher` to target GitHub repositories without static SA keys.
- **Inputs**:
  - `project_id` (`string`, required): GCP Project ID where the service account will be created.
  - `agent_call_name` (`string`, required): Short call name of the agent (e.g., `gustaf`).
  - `human_owner` (`string`, required): Email or username of the human owner (e.g., `johan.granlund`).
  - `agent_type` (`string`, required): Agent classification type label (e.g., `reviewer`, `coder`, `executor`).
  - `workload_identity_pool` (`string`, required): FAST Stage 0 Workload Identity Pool resource name.
  - `github_repository` (`string`, required): Target GitHub repository (`owner/repo`) allowed to impersonate this agent SA.
  - `group_memberships` (`list(string)`, optional, default `[]`): List of user group emails to add this service account to.
  - `custom_labels` (`map(string)`, optional, default `{}`): Additional resource labels.
- **Outputs**:
  - `service_account_id` (`string`): Unique GCP ID of the created service account.
  - `service_account_email` (`string`): Email address of the created service account.
  - `service_account_name` (`string`): Fully qualified resource name (`projects/.../serviceAccounts/...`).
  - `workload_identity_principal` (`string`): Workload Identity principal string for GitHub OIDC binding.
- **ADR References**: [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)

---

### 3. Agent GitHub App (`modules/agent-github-app`)
- **FAST Stage Alignment**: Stage 3 (Tenant Project)
- **Purpose**: Configures GitHub App installations and repository-level access using the `integrations/github` provider.
- **Pre-registered Secret Reference**: References pre-registered Secret Manager secret IDs (`pem_secret_id`) created out-of-band during App registration (ADR-008), using Terraform purely to manage repo installations, permissions, and IAM accessor bindings (`roles/secretmanager.secretAccessor`).
- **Inputs**:
  - `agent_call_name` (`string`, required): Agent call name used to identify the GitHub App (e.g., `agent-gustaf`).
  - `github_organization` (`string`, required): Target GitHub organization name (e.g. `thruput-io`).
  - `target_repositories` (`list(string)`, required): List of repository names the App will be installed on.
  - `pem_secret_id` (`string`, required): Existing Secret Manager secret ID containing the App private key.
  - `permissions` (`map(string)`, optional): Repository and organization permission overrides.
- **Outputs**:
  - `app_id` (`string`): GitHub App ID.
  - `installation_id` (`string`): GitHub App Installation ID for target repositories.
  - `accessor_binding_id` (`string`): IAM secret accessor binding resource ID.
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)

---

### 4. Secret Access (`modules/secret-access`)
- **FAST Stage Alignment**: Stage 3 (Tenant Project)
- **Purpose**: Provisions GCP Secret Manager secret shells (`google_secret_manager_secret`) and grants least-privilege `roles/secretmanager.secretAccessor` IAM roles to authorized agent service accounts.
- **Out-of-Band Payloads**: Secret payload versions are populated out-of-band via GCP Secret Manager API/Console to prevent sensitive secret strings from entering Terraform state files.
- **Inputs**:
  - `project_id` (`string`, required): GCP Project ID hosting Secret Manager.
  - `secret_id` (`string`, required): Canonical secret identifier (e.g. `github-pat-gustaf`).
  - `accessor_service_accounts` (`list(string)`, required): List of agent service account emails granted accessor access.
  - `labels` (`map(string)`, optional, default `{}`): Resource labels for the secret.
- **Outputs**:
  - `secret_id` (`string`): Fully qualified Secret Manager secret ID.
  - `secret_name` (`string`): Secret resource name.
  - `accessor_bindings` (`list(string)`): Applied IAM accessor role bindings.
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)

---

### 5. Resource Tagging (`modules/resource-tagging`)
- **FAST Stage Alignment**: Stage 1 (Resource Manager - Keys/Values) / Stage 3 (Tenant Stage - Bindings)
- **Purpose**: Structure split into two explicit sub-modules to eliminate conditional branching logic:
  - **`modules/resource-tagging/key`** (Stage 1): Manages GCP Resource Manager tag keys and tag values at Organization or Folder parent levels (`google_tags_tag_key`, `google_tags_tag_value`).
  - **`modules/resource-tagging/binding`** (Stage 3): Attaches Tag Value Bindings (`google_tags_tag_binding`) to specific target resources (service accounts, projects, folders).
- **Submodule 5a Inputs (`modules/resource-tagging/key`)**:
  - `parent_id` (`string`, required): GCP Organization or Folder ID (`organizations/...` or `folders/...`).
  - `tag_key_short_name` (`string`, required): Short name of the tag key (e.g., `agent-type`).
  - `tag_values` (`list(string)`, required): Allowed tag value short names (e.g. `["reviewer", "coder", "executor"]`).
- **Submodule 5a Outputs (`modules/resource-tagging/key`)**:
  - `tag_key_id` (`string`): Fully qualified Tag Key ID (`tagKeys/...`).
  - `tag_value_ids` (`map(string)`): Map of tag value short names to fully qualified Tag Value IDs (`tagValues/...`).
- **Submodule 5b Inputs (`modules/resource-tagging/binding`)**:
  - `parent_resource` (`string`, required): Target GCP resource full name (e.g. service account or project ID).
  - `tag_value_id` (`string`, required): Fully qualified Tag Value ID (`tagValues/...`).
- **Submodule 5b Outputs (`modules/resource-tagging/binding`)**:
  - `tag_binding_id` (`string`): Tag Binding resource ID.
- **ADR References**: [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md)

---

### 6. Agent Mailbox (`modules/agent-mailbox`)
- **FAST Stage Alignment**: Stage 3 (Tenant Stage)
- **Purpose**: Provisions Google Workspace agent email aliases using the official `hashicorp/googleworkspace` provider with Domain-Wide Delegation.
- **Inputs**:
  - `domain` (`string`, required): Domain name for agent mail (e.g. `thruput.com`).
  - `agent_call_name` (`string`, required): Short call name of the agent (e.g., `gustaf`).
  - `primary_mailbox_email` (`string`, required): Singleton primary mail account receiving aliases.
- **Outputs**:
  - `alias_email` (`string`): Agent email alias address (`<call-name>@domain`).
  - `primary_mailbox` (`string`): Primary mailbox address.
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md)

---

### 7. MCP Server Runtime (`modules/mcp-server`)
- **FAST Stage Alignment**: Stage 3 (Project Factory / Tenant Project)
- **Purpose**: Provisions containerized serverless compute (Cloud Run) for Model Context Protocol (MCP) tool endpoints.
- **Security & Identity Architecture**:
  - **Strict Private Ingress**: Enforces `ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"` so endpoints are accessible only via private GCP networks (Eventarc / PubSub / Internal VPC).
  - **Identity Separation**: The MCP runtime executes under its own dedicated Service Account (`mcp_service_account_email`), strictly separate from invoking agents or user identities.
  - **On-Demand Secret Resolution**: The MCP server fetches required credentials at runtime via the Secret Manager API (`roles/secretmanager.secretAccessor`) rather than mounting static secret environment variables at container startup.
- **Inputs**:
  - `project_id` (`string`, required): GCP Project ID hosting the Cloud Run service.
  - `region` (`string`, required): GCP region (e.g., `europe-west1`).
  - `server_name` (`string`, required): MCP server instance name (e.g., `mcp-github-tool`).
  - `container_image` (`string`, required): Container image URL in Artifact Registry.
  - `mcp_service_account_email` (`string`, required): Service account email dedicated to executing the MCP server.
  - `env_vars` (`map(string)`, optional, default `{}`): Non-sensitive runtime configuration variables.
  - `invokers` (`list(string)`, optional, default `[]`): Service account or user emails granted `roles/run.invoker`.
- **Outputs**:
  - `service_url` (`string`): HTTPS endpoint URL of the deployed MCP server.
  - `service_name` (`string`): Cloud Run service name.
  - `service_id` (`string`): Fully qualified Cloud Run resource ID.
  - `location` (`string`): Deployed GCP region.
- **ADR References**: [ADR-001](../../adrs/001-pure-terraform-provider-project.md), [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)
