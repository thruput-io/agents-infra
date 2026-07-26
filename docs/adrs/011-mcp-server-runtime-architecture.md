# ADR-011: MCP Server Runtime Architecture & Identity Separation

## Status
Accepted

## Context
Model Context Protocol (MCP) servers host execution tools required by AI agents to interact with external systems (such as GitHub APIs, internal databases, or Google Cloud services). To adhere to security guardrails ([ADR-005](005-modular-design.md), [ADR-008](008-secret-management.md)), MCP tool execution endpoints must enforce strict identity separation, keyless authentication, and private network boundaries.

## Architecture Decisions

### 1. Dedicated Containerized Runtime on Private Cloud Run
* MCP server endpoints are deployed as containerized serverless compute on Google Cloud Run (`modules/mcp-server`).
* Cloud Run ingress is hardcoded to `ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"`. Endpoints are invisible to the public internet and accessible strictly over private GCP VPC networks, Cloud Pub/Sub, or Eventarc internal triggers.

### 2. Three-Tier Identity Separation
Three distinct service accounts enforce least-privilege identity boundaries:
* **Invoking Agent SA** (`agent-<call-name>@<project>.iam.gserviceaccount.com`): Represents the AI agent calling tools. Granted `roles/run.invoker` on specific MCP Cloud Run services. Lacks Secret Manager payload access or GCP admin permissions.
* **MCP Runtime SA** (`mcp-runtime-sa@<project>.iam.gserviceaccount.com`): Container execution identity. Granted `roles/secretmanager.secretAccessor` on required secret shells. Lacks human IAM roles and internet access.
* **FAST Tenant SA**: Management identity used by Terraform during provisioning. Lacks runtime tool execution roles.

### 3. Keyless Instance Metadata OIDC Authentication
* Inbound invocations use Google Cloud Service Accounts as **keyless managed identities** (parity with Azure System-Assigned Managed Identity).
* The Invoking Agent SDK automatically queries the internal GCP Instance Metadata Server (`http://169.254.169.254/computeMetadata/v1/`) to fetch short-lived OIDC identity tokens in memory (`Authorization: Bearer <token>`). Zero static service account keys (`.json`) are created or stored.
* Cloud Run IAM validates the OIDC token signature and `roles/run.invoker` binding before passing requests to the container. Unauthenticated calls (`allUsers`) are forbidden.

### 4. Dynamic Invoker-Driven Secret Resolution
* The MCP server does not inject static secret payloads into container environment variables at startup.
* Upon receiving a tool invocation, the MCP server extracts the caller's verified OIDC identity (`sub` / email claim) and dynamically resolves caller-specific credentials from Secret Manager (e.g., `github-app-pem-gustaf` for `agent-gustaf`).

## Consequences

* **Security**: Total elimination of static API keys and service account JSON keys. Unauthenticated calls are blocked at the GCP IAM boundary.
* **Privilege Isolation**: Invoking agents cannot bypass the MCP tool interface to read Secret Manager secrets directly.
* **Auditing**: Every tool invocation is logged with the invoking agent's verified IAM identity in Google Cloud Audit Logs.
