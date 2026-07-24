# Agent Infra

This is repo is meant to serve for providing the agents module to Google Cloud FAST installation.
It will give agents an identity in the form of service account and home for related resources inside GitHub.

## Objectives

### 1. Google Cloud Identity

Streamline creation of agent identities so that managing their access rights can be easily managed by same means as
human accounts.

### 2. Stateless

This project does not handle any Terraform state by itself more than for testing purposes. Terraform states in this
project are TEST ONLY and has NO VALUE. States that are created for testing purposes should be been discarded as soon as
possible

### 3. GitHub Identity

Give agents a GitHub identity so access to code can be managed via point and click in GitHub web interface and so that
code and code reviews can be attributed

### 4. Secret Identity

When Circumstances Require Agents and Agent Workflows Should Be Used in a Completely Hidden Way from an External
Stand-Point. \
Access Such External Systems will then be done in a strict on-Behalf of Human User Way. \
But at the Same Time It Should Be Equally Easy to Assign Agents Fine Grained Access Rights and Not Handing out the Human
Access Rights for That External System. Most Important External System Is \
(Azure ADO).

### 5. Opaque Secrets

Making it easy to share personal access tokens with agents in a secure way.\
Agents should never access the secret directly.\
Authentication should be hidden to agents and secrets used should never be in agents reach.

### 6. Canonical Resources

Abstracting external systems and resources from agents via a canonical resource reference,\

#### Format
    res::{kind}/\[{groupings}\]{n}/{name}
#### Samples
    res::repo/github/thruput/google-dev
    res::secret/github-pat/johan/read-only
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


### Artifacts

#### Terraform Modules

##### 1. Access Group
_{terraform include name access groups}_

Agent service accounts will never be granted roles directly. Roles will be granted via user groups.
This module will house all user groups and role assignments to those groups.
Group names follow the FAST convention — see [ADR-008](README.md#adr-008-fast-group-naming).

##### 3. Service Accounts
_{terraform include name service accounts}_

Creates a service account with an `agent-type` Resource Manager tag binding (see [ADR-009](README.md#adr-009-resource-manager-tags-for-agent-identity))
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

##### 4. Service Accounts
_{terraform include name service accounts}_

Creates a service account with an `agent-type` Resource Manager tag binding (see [ADR-009](README.md#adr-009-resource-manager-tags-for-agent-identity))
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

##### 5. Agent GitHub App
_{terraform include name github app}_

Configures a GitHub App to act as the agent's identity and access bridge to GitHub, so commits, PRs and reviews
are attributed to the agent rather than a human user (Objective [GitHub Identity](README.md#3-github-identity)).
One App per agent, one PEM per agent — see [ADR-010](README.md#adr-010-one-github-app-per-agent).

The App itself must be registered once via the GitHub UI or [App Manifest flow](https://docs.github.com/en/apps/sharing-github-apps/registering-a-github-app-from-a-manifest)
— GitHub does not expose an API to create Apps without a human consent step. The PEM produced at registration
is uploaded to GCP Secret Manager under a per-agent secret name and never leaves that boundary (Objectives
[Opaque Secrets](README.md#5-opaque-secrets), ADR-007).

This module then, using the [`integrations/github`](https://registry.terraform.io/providers/integrations/github/latest/docs) provider:

- installs the App on the agent's target repositories and sets per-repo permissions,
- exposes `app_id` and `installation_id` as outputs so downstream stages can reference the identity,
- leaves token minting to the runtime MCP layer, which calls the `github_app_token` data source (or the
  equivalent REST endpoint) to hand a short-lived installation token to the agent on demand.

The App name incorporates the agent's [Call Name](README.md#adr-005-call-name), e.g. `agent-gustaf`, so the
identity is discoverable from the same reference used elsewhere.

##### 6. Agent Mailbox
_{terraform include name mailbox}_

Provisions a singleton agent mailbox on google mail. (see [ADR-006](README.md#adr-006-email))

Per agent this module:

- Creates an alias `<call-name>@thruput.com` on the mail singleton mail account.

##### 7. Agent tags
(ai fill in)

##### 8. 
