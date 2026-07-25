# Modules Plan

## Artifacts

### Terraform Modules

#### 1. Access Group
_{terraform include name access groups}_

Agent service accounts will never be granted roles directly. Roles will be granted via user groups.
This module will house all user groups and role assignments to those groups.
Group names follow the FAST convention — see [ADR-008](../../adrs/008-secret-management.md).

#### 2. Service Accounts
_{terraform include name service accounts}_

Creates a service account with an `agent-type` Resource Manager tag binding (see [ADR-005](../../adrs/005-modular-design.md))
and descriptive labels carrying call name and human owner.
Sample:
```hcl
tag_bindings = {
    agent-type = "$tag_values:agent-type/reviewer"
}
labels = {
    agent-call-name   = "gustaf"
    agent-human-owner = "johan.granlund"
}
```

#### 3. Agent GitHub App
_{terraform include name github app}_

Configures a GitHub App to act as the agent's identity and access bridge to GitHub, so commits, PRs and reviews
are attributed to the agent rather than a human user (Objective [GitHub Identity](../../../README.md#3-github-identity)).
One App per agent, one PEM per agent — see [ADR-008](../../adrs/008-secret-management.md).

The App itself must be registered once via the GitHub UI or [App Manifest flow](https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-from-a-manifest)
— GitHub does not expose an API to create Apps without a human consent step. The PEM produced at registration
is uploaded to GCP Secret Manager under a per-agent secret name and never leaves that boundary (Objectives
[Opaque Secrets](../../../README.md#5-opaque-secrets), [ADR-007](../../adrs/007-dependency-and-provider-version-management.md)).

This module then, using the [`integrations/github`](https://registry.terraform.io/providers/integrations/github/latest/docs) provider:

- installs the App on the agent's target repositories and sets per-repo permissions,
- exposes `app_id` and `installation_id` as outputs so downstream stages can reference the identity,
- leaves token minting to the runtime MCP layer, which calls the `github_app_token` data source (or the
  equivalent REST endpoint) to hand a short-lived installation token to the agent on demand.

The App name incorporates the agent's Call Name, e.g. `agent-gustaf`, so the
identity is discoverable from the same reference used elsewhere.

#### 4. Agent Mailbox
_{terraform include name mailbox}_

Provisions a singleton agent mailbox on google mail.

Per agent this module:

- Creates an alias `<call-name>@thruput.com` on the mail singleton mail account.

#### 5. Agent tags
(ai fill in)
