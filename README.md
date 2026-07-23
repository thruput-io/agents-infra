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

## Architecture

### ADR-001 Pure Terraform Provider Project

This is a pure resource project providing Terraform modules for inclusion by the actual state holding infra projects
provided by the FAST setup.

### ADR-002 Terraform Stateless

This project should not have any Terraform state by itself other than for testing.\
To simplify destruction of resources transient test projects will be utilized for integration testing\
where the entire project where test-deployment is happening can be destroyed after test-runs.

### ADR-003 Public Repo and GitHub Distribution

To be able to act as a provider to Terraform projects in a straight forward way by referencing projects files directly
via GitHub.

### ADR-004 Only Transient Secrets

This project will not should not handle or maintain any secrets. Any secrets needed for tests should be
destroyed/expired when test run completes.

### ADR-005 Call Name

All agents will be given a human name. It has to be unique withing the FAST installation. It is used as the reference to
agent and\
all resources belonging to the agent should be tagged as agent with and

### ADR-006 Email

Each agent gets an email address so external systems that require one (signup flows, verification codes, notification
recipients) work out of the box. Constraints:

- **No paid seats.** Google Workspace / Microsoft 365 licenses per agent are rejected on cost grounds.
- **Isolation.** An agent must not be able to read another agent's mail.
- **Wipeable.** It must be possible to clear an agent's mailbox on demand or on a schedule, without touching other
  agents' data.

The chosen approach is **one shared Gmail inbox behind a catch-all custom domain**, with per-agent isolation and
wipe enabled by the mail MCP server rather than by the mail account itself. Concretely:

- A single Gmail account holds all agent mail. Its OAuth refresh token lives in Secret Manager.
- A custom domain (e.g. `agents.<org>.example`) uses a free catch-all forwarder (Cloudflare Email Routing) to send
  `<call-name>@agents.<org>.example` into that shared inbox.
- The mail MCP (see [ADR-007](README.md#adr-007-egress)) authenticates once with the shared credentials and exposes a
  per-agent API surface. It filters reads by the `Delivered-To:` header so an agent only ever sees mail addressed to
  its own alias; send operations set `From:` to the agent's alias; wipe is a filtered trash-and-purge scoped to one
  alias.

Trade-off: isolation is enforced by MCP code, not by mail-server credentials. That is consistent with the ADR-007
trust posture but makes the alias-filter logic in the MCP a critical review target and warrants an integration test
that verifies alias boundaries cannot be crossed.

### ADR-007 Egress

All interaction to outer world is handled via MCP-servers that can provide authentication/authorization.\
MCP servers should be thin wrappers so that underlying services can be utilized in a transparent way by agents.\
Only security or Mission Critical rules is enforced via them. For instance controlling what signature is used on git commits.
That gives the control needed to achieve objective [Secret Identity](README.md#4-secret-identity)

### ADR-008 FAST Group Naming

All IAM groups created or referenced by this project follow the Cloud Foundation Fabric FAST naming convention
so agent groups can be bound via the same `context.iam_principals` alias mechanism as human groups.\
The canonical aliases are `gcp-organization-admins`, `gcp-billing-admins`, `gcp-network-admins`, `gcp-security-admins`,
`gcp-devops` and `gcp-support` — see the [FAST domainless-iam ADR](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/blob/master/adrs/fast/0-domainless-iam.md) for the authoritative set.\
Agent-specific groups extend the same `gcp-<role>[-<qualifier>]` shape, where `<qualifier>` is typically the agent's
[Call Name](README.md#adr-005-call-name), for example `gcp-agent-reviewers` or `gcp-agent-<call-name>`.

### ADR-009 Resource Manager Tags for Agent Identity

Agent-type classification is expressed as a Resource Manager tag binding, not a label, so it can drive IAM conditions
and org-policy conditions (e.g. only service accounts bound to `agent-type/reviewer` may impersonate a given resource).\
This project defines a canonical `agent-type` tag key with a controlled set of values (`reviewer`, `writer`, ...) and
follows FAST's convention of exposing it via the `$tag_keys:agent-type` alias so downstream stages can reference it
without hard-coding IDs — see FAST's [tag definitions](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast/stages/0-org-setup/datasets/hardened/organization/tags) for the pattern.\
Other tags are  (`agent-call-name`, `agent-human-owner`).

### ADR-010 One GitHub App Per Agent

Each agent gets its own dedicated GitHub App, and therefore its own PEM private key. A shared "platform" App
with many installations was rejected because a single compromised PEM would let an attacker impersonate every
agent, and per-agent permission scoping would collapse into the union of all agents' needs.\
One App per agent means: strong blast-radius isolation, per-agent revocation (delete the App to fully retire
the identity), and clean attribution — commits and PRs carry the agent's own bot user. The trade-off is one
manual App registration per agent (see [ADR-007 Egress](README.md#adr-007-egress) constraint on bootstrap)
and one PEM per agent stored in Secret Manager.


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
