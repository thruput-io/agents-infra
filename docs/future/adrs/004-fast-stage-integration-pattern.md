# 4. FAST Stage Integration Pattern

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
Google Cloud FAST organizes infrastructure governance into decoupled, security-bounded stages (e.g. 0-bootstrap, 1-resman, 2-networking, 3-project-factory). Agent infrastructure setup must integrate seamlessly into this multi-stage architecture.

## Decision
1. **Module Composition in Stages**: Downstream FAST stages (e.g. stage 3 project factory or specialized tenant stages) **MUST** instantiate modules from this repository as provider submodules.
2. **Contract Interfaces**: Modules **MUST** expose standard input variables and output interfaces matching FAST stage contract conventions (e.g. project IDs, service account emails, IAM roles, and Secret Manager references).
3. **Decoupled IAM Boundaries**: Modules **MUST NOT** assume super-admin privileges; they operate strictly within the IAM boundaries delegated to the specific consuming FAST stage.

## References
* [Fabric FAST Stages & Contracts](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast/stages)

## Consequences
* **Clean Security Boundaries**: Aligns agent infrastructure setup with FAST security boundaries and stage delegation.
* **Native Interoperability**: Inputs and outputs flow naturally between FAST stages and agent submodules.
