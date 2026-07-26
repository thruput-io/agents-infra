# Modules Plan & Terraform Interface Contracts

This document defines the complete set of single-responsibility Terraform modules under `modules/`, detailing their FAST stage alignment, input contracts, and output contracts to ensure seamless integration into Google Cloud FAST.

---

## Terraform Submodules Taxonomy & Interface Contracts

### 1. Access Group (`modules/access-group`)
- **FAST Stage Alignment**: Stage 1 (Resource Manager) / Stage 3 (Tenant/Project Factory)
- **Purpose**: Provisions GCP User Groups and FAST IAM role assignments to those groups. Agent service accounts are granted roles exclusively via group membership.
- **Inputs**:
  - `organization_id` (`string`, required): GCP Organization ID where groups reside.
  - `prefix` (`string`, optional, default `null`): Standard FAST naming prefix (e.g. `fast-agent`).
  - `group_definitions` (`map(object({ display_name = string, description = string }))`, required): Map of group keys to group metadata.
  - `group_iam_roles` (`map(list(string))`, optional, default `{}`): Map of group keys to lists of GCP IAM role names.
- **Outputs**:
  - `group_emails` (`map(string)`): Map of group keys to group email addresses.
  - `group_ids` (`map(string)`): Map of group keys to Cloud Identity group IDs.
  - `iam_bindings` (`map(list(string))`): Applied IAM role bindings per group key.
- **ADR References**: [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md)

---

### 2. Agent Identity (`modules/agent-identity`)
- **FAST Stage Alignment**: Stage 3 (Project Factory / Tenant Project)
- **Purpose**: Creates GCP Service Accounts with descriptive labels (`agent-call-name`, `agent-human-owner`), Resource Manager tag bindings (`agent-type`), and **GitHub Workload Identity Federation (WIF)** bindings for zero-secret CI/CD & event publishing.
- **Zero-Secret Integration**: Integrates directly with FAST Stage 0 Workload Identity Pools (`projects/*/locations/global/workloadIdentityPools/github-pool`) to bind `roles/iam.workloadIdentityUser` and `roles/pubsub.publisher` to target GitHub repositories without any static service account keys.
- **Inputs**:
  - `project_id` (`string`, required): GCP Project ID where the service account will be created.
  - `agent_call_name` (`string`, required): Short call name of the agent (e.g., `gustaf`).
  - `human_owner` (`string`, required): Email or username of the human owner (e.g., `johan.granlund`).
  - `agent_type` (`string`, required): Agent classification type (e.g., `reviewer`, `coder`, `executor`).
  - `workload_identity_pool` (`string`, optional): FAST Stage 0 Workload Identity Pool name for GitHub federation.
  - `github_repository` (`string`, optional): Target GitHub repository (`owner/repo`) allowed to impersonate this agent SA.
  - `group_memberships` (`list(string)`, optional, default `[]`): List of user group emails to add this service account to.
  - `custom_labels` (`map(string)`, optional, default `{}`): Additional resource labels.
- **Outputs**:
  - `service_account_id` (`string`): Unique GCP ID of the created service account.
  - `service_account_email` (`string`): Email address of the created service account.
  - `service_account_name` (`string`): Fully qualified resource name (`projects/.../serviceAccounts/...`).
  - `workload_identity_principal` (`string`): Workload Identity principal string for GitHub OIDC binding.
  - `tag_bindings` (`map(string)`): Map of Resource Manager tag bindings applied to the service account.
- **ADR References**: [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)

---

### 3. Agent GitHub App (`modules/agent-github-app`)
- **FAST Stage Alignment**: Stage 3 (Tenant Project)
- **Purpose**: Configures GitHub App installations and repository-level access using the `integrations/github` provider. Secret PEMs are stored securely in Secret Manager and referenced opaquely.
- **Inputs**:
  - `agent_call_name` (`string`, required): Agent call name used to identify the GitHub App (e.g., `agent-gustaf`).
  - `github_organization` (`string`, required): Target GitHub organization name (e.g. `thruput-io`).
  - `target_repositories` (`list(string)`, required): List of repository names the App will be installed on.
  - `permissions` (`map(string)`, optional): Repository and organization permission overrides.
  - `secret_manager_project_id` (`string`, required): GCP Project ID where the App PEM secret is stored.
- **Outputs**:
  - `app_id` (`string`): GitHub App ID.
  - `installation_id` (`string`): GitHub App Installation ID for target repositories.
  - `pem_secret_id` (`string`): Secret Manager secret ID containing the App private key.
  - `pem_secret_version` (`string`): Active secret version ID for the App private key.
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)

---

### 4. Secret Access (`modules/secret-access`)
- **FAST Stage Alignment**: Stage 3 (Tenant Project)
- **Purpose**: Provisions GCP Secret Manager secrets (`google_secret_manager_secret`) and grants least-privilege `roles/secretmanager.secretAccessor` IAM roles to authorized agent service accounts.
- **Inputs**:
  - `project_id` (`string`, required): GCP Project ID hosting Secret Manager.
  - `secret_id` (`string`, required): Canonical secret identifier (e.g. `github-pat-gustaf`).
  - `secret_data` (`string`, required, sensitive): Plaintext secret payload to store.
  - `accessor_service_accounts` (`list(string)`, required): List of agent service account emails granted accessor access.
  - `labels` (`map(string)`, optional, default `{}`): Resource labels for the secret.
- **Outputs**:
  - `secret_id` (`string`): Fully qualified Secret Manager secret ID.
  - `secret_name` (`string`): Secret resource name.
  - `version_id` (`string`): Latest created secret version string.
  - `accessor_bindings` (`list(string)`): Applied IAM accessor role bindings.
- **ADR References**: [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)

---

### 5. Resource Tagging (`modules/resource-tagging`)
- **FAST Stage Alignment**: Stage 1 (Resource Manager) / Stage 3 (Tenant/Project Factory)
- **Purpose**: Manages GCP Resource Manager tag keys, tag values, tag bindings, and tag IAM roles to enforce identity, access governance, and security classification across GCP resources.
- **Inputs**:
  - `parent_id` (`string`, required): GCP Organization or Folder ID where tag keys reside.
  - `tag_key_short_name` (`string`, required): Short name of the tag key (e.g., `agent-type`).
  - `tag_values` (`list(string)`, required): List of allowed tag value short names (e.g. `["reviewer", "coder", "executor"]`).
  - `resource_tag_bindings` (`map(string)`, optional, default `{}`): Map of target resource names (e.g. project or service account) to tag value short names.
- **Outputs**:
  - `tag_key_id` (`string`): Fully qualified Tag Key ID (`tagKeys/...`).
  - `tag_value_ids` (`map(string)`): Map of tag value short names to fully qualified Tag Value IDs (`tagValues/...`).
  - `tag_bindings` (`map(string)`): Map of target resource names to Tag Binding resource names.
- **ADR References**: [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md)

---

### 6. Agent Mailbox (`modules/agent-mailbox`)
- **FAST Stage Alignment**: Stage 3 (Tenant Stage)
- **Purpose**: Provisions singleton Google Workspace/Mail accounts and creates per-agent email aliases (`<call-name>@thruput.com`).
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
- **Purpose**: Provisions containerized serverless compute (Cloud Run), invoker IAM roles (`roles/run.invoker`), Workload Identity integration, and runtime Secret Manager environment variable injection for Model Context Protocol (MCP) server tools.
- **Inputs**:
  - `project_id` (`string`, required): GCP Project ID hosting the Cloud Run service.
  - `region` (`string`, required): GCP region (e.g., `europe-west1`).
  - `server_name` (`string`, required): MCP server instance name (e.g., `mcp-github-tool`).
  - `container_image` (`string`, required): Container image URL in Artifact Registry.
  - `service_account_email` (`string`, required): Service account email executing the MCP server container.
  - `env_secrets` (`map(string)`, optional, default `{}`): Map of environment variable names to Secret Manager secret IDs.
  - `env_vars` (`map(string)`, optional, default `{}`): Non-sensitive environment variables.
  - `invokers` (`list(string)`, optional, default `[]`): Service account or user emails granted `roles/run.invoker`.
- **Outputs**:
  - `service_url` (`string`): HTTPS endpoint URL of the deployed MCP server.
  - `service_name` (`string`): Cloud Run service name.
  - `service_id` (`string`): Fully qualified Cloud Run resource ID.
  - `location` (`string`): Deployed GCP region.
- **ADR References**: [ADR-001](../../adrs/001-pure-terraform-provider-project.md), [ADR-004](../../adrs/004-fast-stage-integration-pattern.md), [ADR-005](../../adrs/005-modular-design.md), [ADR-008](../../adrs/008-secret-management.md)
