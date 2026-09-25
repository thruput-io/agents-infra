# google-chat-infra Specification & Deployment Plan

This repository component defines the GCP infrastructure, Workload Identity Federation (WIF), Google Chat API, Pub/Sub messaging, and Cloud Run subscription filtering for automated agents (such as `rasmus`).

---

## 1. Overview & Business Purpose

To enable automated AI agents (like `rasmus`) to securely interact with Google Chat spaces without storing permanent GCP service account JSON key files:
1. **Keyless Token Minting**: WIF exchanges GitHub App private key credentials (in `~/secrets`) for short-lived GCP tokens (`https://www.googleapis.com/auth/chat.bot`).
2. **Dedicated Pub/Sub Topics**: One Pub/Sub topic per agent identity (`topics/rasmus-chat-events`) handles inbound messages from Google Chat.
3. **Attribute-Based Cloud Run Auto-Wakeup**: Pub/Sub Push subscriptions filter messages using `attributes.target = "johans-laptop"`. Sleeping containers only wake up when explicitly targeted, preserving zero-cost idle state.

> [!IMPORTANT]
> **Service Account Security Boundary**: While the GCP Service Account (`rasmus-agent-sa`) represents the canonical identity of the agent, **direct key access or raw credential export to the Service Account is NEVER granted**. Minting tokens via GitHub App credentials and Workload Identity Federation (WIF) only issues short-lived, dynamically scoped OAuth access tokens (`https://www.googleapis.com/auth/chat.bot`) evaluated against strict CEL attribute constraints. No static Service Account key files are ever created, exported, or exposed to the agent or GitHub.

### Cross-References

| Repository | Branch / PR | Plan Specification |
|---|---|---|
| `thruput-io/gettoken` | [`001-mezzy-google-chat`](https://github.com/thruput-io/gettoken/tree/001-mezzy-google-chat) | [`docs/plans/mezzy-google-chat/001-mezzy-google-chat.md`](https://github.com/thruput-io/gettoken/blob/001-mezzy-google-chat/docs/plans/mezzy-google-chat/001-mezzy-google-chat.md) |

---

## 2. Infrastructure Components

| Layer | Component | Details |
| :--- | :--- | :--- |
| **Identity** | Service Account | `rasmus-agent-sa@<project_id>.iam.gserviceaccount.com` |
| **Auth** | Workload Identity Federation | Pool: `github-pool`, Provider: `github-provider`, CEL Condition: `attribute.repository == "thruput-io/gettoken" && attribute.actor == "rasmus"` |
| **Ingress** | Google Chat API | Connection: Cloud Pub/Sub, Topic: `projects/<project_id>/topics/rasmus-chat-events` |
| **Messaging** | Pub/Sub Topic | Dedicated topic `rasmus-chat-events` with `chat-api-push@system.gserviceaccount.com` Publisher role |
| **Routing** | Pub/Sub Push Subscription | `rasmus-johans-laptop-sub` with message filter `attributes.target = "johans-laptop"` |
| **Runtime** | Cloud Run Service | Scale-to-zero container (`min-instances = 0`) woken up via HTTPS POST on Pub/Sub delivery |

---

## 3. Ansible Role Integration

The Ansible role `google_chat_infra` located at `src/roles/google_chat_infra` provisions all required GCP resources idempotently:

```bash
ansible-playbook -i inventory/hosts.yml src/playbooks/google_chat_infra.yml
```

### Key Role Variables (`src/roles/google_chat_infra/defaults/main.yml`)
* `gcp_project_id`: Target Google Cloud project ID.
* `agent_name`: Name of the agent (`rasmus`).
* `service_account_name`: `rasmus-agent-sa`.
* `pubsub_topic_name`: `{{ agent_name }}-chat-events`.
* `pubsub_target_host`: `johans-laptop`.
