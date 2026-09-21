# 6. Compliance Framework & Pre-Push Security Guardrails

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
Secrets pushed to git remotes compromise credentials instantly. Security misconfigurations must be caught on the developer machine prior to `git push` and verified in CI using policy-as-code guardrails.

## Decision
1. **Repository-Prepared Pre-Push Hooks**: The repository **MUST** commit version-controlled hook configurations (`.pre-commit-config.yaml` and `.githooks/pre-push`) running Gitleaks and Checkov prior to `git push`.
2. **Server-Side Push Protection**: The repository **MUST** enable GitHub Secret Scanning with Push Protection as a server-side safety net.
3. **Policy-as-Code Verification**: Pull Requests **MUST** run Conftest in CI against defined Rego policies (such as standard CFT policy bundles).
4. **Zero Hardcoded Secrets**: Modules **MUST NOT** accept plaintext secrets in `default` variables; all secrets MUST be injected via Secret Manager references.

## References
* [Gitleaks Secret Detection Engine](https://github.com/gitleaks/gitleaks)
* [Checkov Static Security Analysis](https://www.checkov.io)
* [Conftest Policy Testing Framework](https://www.conftest.dev)

## Consequences
* **Pre-Push Prevention**: Secrets and misconfigurations are intercepted on the local machine before reaching the remote repository.
* **Automated Compliance**: Ensures all modules conform to enterprise-wide security policies.
