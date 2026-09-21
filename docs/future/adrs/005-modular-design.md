# 5. Modular Design & Separation of Responsibilities

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
As agent infrastructure grows (handling service accounts, Workload Identity, secret access, mailboxes, and resource tags), monolithic Terraform configurations become brittle and difficult to maintain.

## Decision
1. **Single-Responsibility Submodules**: Infrastructure functionality **MUST** be divided into focused, single-purpose submodules under `modules/` (e.g. `modules/agent-identity`, `modules/secret-access`, `modules/resource-tagging`).
2. **Resource + IAM Encapsulation**: Each submodule **MUST** encapsulate resource creation alongside its corresponding IAM role bindings.
3. **Zero Side-Effects**: Submodules **MUST NOT** execute external local-exec scripts or rely on unmanaged side effects; they must rely purely on declarative Terraform resource definitions.

## References
* [Fabric Modules Design Suite](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules)

## Consequences
* **High Maintainability**: Each submodule can be modified, tested, and upgraded independently.
* **Low Coupling**: Downstream FAST stages can compose only the specific submodules they need.
