# 8. Secret Management & Credentials

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
Agent infrastructure handles sensitive credentials (API tokens, private keys, service account keys, and mailbox secrets). Writing or exposing plaintext secrets in Terraform configuration files, state outputs, or default variables violates security compliance.

## Decision
1. **Google Cloud Secret Manager Integration**: All sensitive agent credentials **MUST** be stored and managed in Google Cloud Secret Manager (`google_secret_manager_secret` and `google_secret_manager_secret_version`).
2. **Zero Plaintext Values**: Modules **MUST NOT** accept plaintext secrets in `default` variables, output sensitive values in unencrypted state logs, or commit secrets to git repositories.
3. **Least-Privilege Secret IAM**: Modules **MUST** grant secret access exclusively to authorized agent service accounts using narrow Secret Manager Secret Accessor IAM roles (`roles/secretmanager.secretAccessor`).

## References
* [Fabric Secret Manager Module](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/modules/secret-manager)

## Consequences
* **Enhanced Security**: Credentials are encrypted at rest in GCP Secret Manager and managed with granular audit logs.
* **Least-Privilege Access**: Only designated agent service accounts receive read access to required secret versions.
