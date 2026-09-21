# 2. Ephemeral Integration Testing & Teardown

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
Modules in this repository must be verified before release. To comply with Google Cloud Foundation guidelines and prevent resource sprawl, integration testing must not leave orphaned GCP resources.

## Decision
1. **Ephemeral Test Sandboxes**: Integration tests MUST execute in short-lived, dynamically provisioned GCP test projects managed entirely by automated CI pipelines.
2. **Guaranteed Teardown**: Pipelines MUST execute automated `terraform destroy` and project deletion (`gcloud projects delete`). Pipeline failure hooks MUST guarantee cleanup even if a test suite crashes.
3. **No Manual Testing**: Ad-hoc local state testing is prohibited; all verification must occur in hermetic CI test runners.

## References
* [Fabric FAST Stages & Contracts](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast)

## Consequences
* **Zero Resource Sprawl**: Automatic teardown prevents lingering test resources or costs.
* **Hermetic Verification**: Isolated, repeatable CI test execution matching FAST standards.
