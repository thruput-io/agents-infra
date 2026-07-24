# AGENTS

This document serves as the primary entry point and rule index for AI agents operating within the `agents-infra` repository.

> [!IMPORTANT]
> Before performing **ANY** task in this project, you **MUST** read and **STRICTLY** follow the governance rules linked below.
---

## 🏛️ Rule Documents & Governance Index

The following documents define the binding operational and coding standards for this repository.

| Document | Scope & Description | Key Focus |
| :--- | :--- | :--- |
| **[`RULES.md`](./RULES.md)** | **Imperative** coding standards | Technical and structural rules using RFC 2119 keywords (*MUST*, *SHOULD*, *MAY*). |
| **[`PHILOSOPHY.md`](./PHILOSOPHY.md)** | Quality definition & principles | Core quality framework; consult when rules do not explicitly resolve a question. |
| **[`WORKFLOW.md`](./WORKFLOW.md)** | Git hygiene & evidence requirements | Guidelines for branching, commit standards, testing, and evidence collection. |
| **[`PLANNING.md`](./PLANNING.md)** | Task planning & execution tracking | Requirements for task breakdown, execution plans, and progress tracking. |

---

## 📐 Architecture & ADRs Index

Architecture and design decisions are captured in Architectural Decision Records (ADRs):

- **[`docs/adrs/`](./docs/adrs/)** — Folder containing numbered, immutable ADRs (`001`, `002`, ...).
  - **Immutability & Delta Rule**: ADRs are strictly **immutable**. Each new ADR represents an incremental delta from previous ones.
  - **Precedence**: In case of conflict between ADRs, the **latest (highest-numbered) ADR completely replaces earlier ones**.
- **[`docs/plans/`](./docs/plans/)** — Active and historical task immutable execution plans.

---

## 🚨 Precedence, Conflicts & Ambiguity Protocol

### 1. Precedence of Authority
These governance documents and ADRs represent a **higher authority** than the current task prompt or user instructions.

### 2. Conflict Resolution
If a task conflicts with any governance rule or ADR:
1. 🛑 **MUST NOT proceed**; stop immediately.
2. 📢 **Explain the conflict** explicitly.
3. ❓ **Ask for clarification** from the user.

### 3. Handling Doubt & Ambiguity
If in doubt or facing ambiguity:
1. 🛑 **MUST NOT** retreat to assumed defaults, prior habits, or unverified conventions.
2. 📖 **MUST** read [`PHILOSOPHY.md`](./PHILOSOPHY.md) to find clarity and align with core principles.

---

## 🔄 Agent Execution Protocol

```
1. INDEX & READ  ──> Read AGENTS.md, governance docs (RULES, PHILOSOPHY, WORKFLOW, PLANNING), and latest ADRs.
2. VERIFY PLAN   ──> Validate task design against RULES.md and ADRs in docs/adrs/. Read ADRs from highest to lowest number, ignore conflicting earlier ADRs.
3. EXECUTE       ──> Apply changes adhering strictly to WORKFLOW.md (git hygiene & verification evidence).
4. RESOLVE       ──> If conflicts or ambiguity arise, STOP and seek user clarification per PHILOSOPHY.md.
```
