# 12. Deterministic Infrastructure

* **Status**: Accepted
* **Date**: 2026-07-26

## Context
Infrastructure consistency and predictability are foundational to our agent management lifecycle. Modules and provisioning scripts deployed across Google Cloud FAST stages (Stage 0 through Stage 3) must behave deterministically across all deployments without unverified conditional logic or out-of-band mutations.

## Decision
1. **Codified State & Zero Manual Mutation**: The entirety of the agent infrastructure **MUST** be defined and managed strictly as code. Manual mutations (via interactive console or ad-hoc CLI changes) are strictly prohibited.
2. **Strict Idempotency**: All Terraform submodules and setup scripts **MUST** be strictly idempotent. Executing `terraform apply` against an existing target **MUST** produce zero state diff once desired state is reached.
3. **Module Agnosticism & Zero Conditional Branching**: Terraform submodules under `modules/` **MUST** be linear, declarative units with zero conditional branching (`count = var.enable ? 1 : 0` or environment `if`/`case` switches) based on execution context.
4. **Explicit Variable Injection**: Every variable required by a submodule **MUST** be explicitly provided by the caller. Internal fallback magic or unverified implicit defaults are prohibited.
5. **Reproducible Birth**: Provisioning any component (Service Account, Secret Shell, Cloud Run service) is a deterministic event. Identical input configurations **MUST** produce bit-for-bit parity across all deployment targets.

## References
* [ADR-001: Pure Terraform Provider Project](001-pure-terraform-provider-project.md)
* [ADR-005: Modular Design & Separation of Responsibilities](005-modular-design.md)

## Consequences
* **Predictability**: Infrastructure behavior is consistent and verifiable across all FAST stages.
* **Traceability**: Every state change is backed by source-controlled configuration commits.
* **Robustness**: Explicit injection ensures configuration errors fail early and loudly.
