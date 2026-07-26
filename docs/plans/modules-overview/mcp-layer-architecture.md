# MCP Layer Architecture & Identity Specification

This document details the runtime architecture, identity separation, network ingress rules, authentication protocols, and dynamic secret resolution strategy for the Model Context Protocol (MCP) server layer (`modules/mcp-server`) within Google Cloud FAST infrastructure.

---

## 1. Architectural Overview

The MCP layer acts as a secure, containerized tool execution gateway hosted on Google Cloud Run. It sits between invoking AI Agents (or internal trigger sources) and external/internal APIs (e.g., GitHub, GCP APIs, databases).

```mermaid
sequenceDiagram
    autonumber
    actor Agent as Invoking Agent SA<br/>(agent-gustaf@...)
    participant IAM as GCP Cloud Run IAM<br/>(roles/run.invoker)
    participant MCP as MCP Server (Cloud Run)<br/>(ingress = internal)
    participant SM as Secret Manager API
    participant GH as External API / GitHub

    Agent->>IAM: 1. HTTP POST + OIDC Bearer Token
    IAM->>MCP: 2. Validate OIDC token & pass request + caller identity
    MCP->>SM: 3. Dynamic Secret Resolution based on caller SA
    SM-->>MCP: 4. Return caller-specific short-lived token
    MCP->>GH: 5. Execute tool call with caller's token
    GH-->>MCP: 6. Return raw payload
    MCP-->>Agent: 7. Return sanitized response
```

---

## 2. Identity Separation & Least Privilege

To maintain strict security boundaries, the MCP architecture enforces three distinct service account identities:

| Identity | Service Account | Granted IAM Roles | Security Constraints |
| :--- | :--- | :--- | :--- |
| **Invoking Agent SA** | `agent-<call-name>@<project>.iam.gserviceaccount.com` | `roles/run.invoker` on specific MCP Cloud Run services | • Cannot access Secret Manager payloads directly.<br/>• Lacks GCP admin rights. |
| **MCP Runtime SA** | `mcp-runtime-sa@<project>.iam.gserviceaccount.com` | `roles/secretmanager.secretAccessor` on required secret shells | • Container execution identity.<br/>• Inaccessible from public internet.<br/>• Has no human/user IAM roles. |
| **FAST Tenant SA** | Stage 3 Management SA | Provisioning roles (`roles/run.admin`, `roles/iam.serviceAccountAdmin`) | • Used exclusively during Terraform provisioning, never at runtime. |

---

## 3. Network Ingress & Invoker Governance

* **Strict Private Ingress**: Cloud Run services are configured with `ingress = "INGRESS_TRAFFIC_INTERNAL_ONLY"`. The endpoint is invisible and inaccessible from the public internet. It receives traffic strictly via internal VPC routes, Eventarc, or Cloud Pub/Sub triggers.
* **Invoker Role Enforcement**: Public/unauthenticated calls (`allUsers`) are strictly blocked. Invocation rights are granted explicitly to authorized Invoking Agent service accounts via `roles/run.invoker`.

---

## 4. Two-Tier Authentication & Dynamic Secret Resolution

### Tier 1: Inbound Invoker Authentication (OIDC ID Token)
1. The Invoking Agent requests a Google-signed OIDC ID Token targeted at the MCP Cloud Run service URL (`aud = https://mcp-server-xyz.a.run.app`).
2. The agent sends an HTTP request with `Authorization: Bearer <Google_OIDC_ID_Token>`.
3. GCP Cloud Run infrastructure validates the OIDC JWT signature and checks `roles/run.invoker`. Unverified requests are rejected at the GCP IAM boundary with `403 Forbidden`.

### Tier 2: Dynamic Secret Resolution per Invoker Identity
1. Upon receiving an authenticated request, the MCP container extracts the verified caller identity (`email` / `sub` claim from the OIDC token, e.g. `agent-gustaf@...`).
2. **Identity-Driven Secret Mapping**: The secret/credential fetched by the MCP server **dynamically shifts based on the authenticated identity of the invoker**.
   - Example: If `agent-gustaf` calls the MCP server, the MCP layer fetches `github-app-pem-gustaf` or `github-pat-gustaf`.
   - If `agent-alex` calls the MCP server, the MCP layer fetches `github-app-pem-alex` or `github-pat-alex`.
3. The MCP server fetches the caller's specific credential from Secret Manager using its `mcp-runtime-sa` identity, executes the downstream API call, and returns the result to the caller without ever exposing raw secret payloads to the invoking agent.
