# 9. Automated CI/CD Pipeline Integration

* **Status**: Accepted
* **Date**: 2026-07-24

## Context
Manual testing, linting, and release tagging are prone to human error. Automated CI/CD pipelines are essential to continuously validate code quality, security compliance, and module formatting before changes reach production branches.

## Decision
1. **GitHub Actions Automation**: All Pull Requests and `main` branch commits **MUST** trigger automated CI workflows defined under `.github/workflows/`.
2. **Automated Verification Matrix**: The CI pipeline **MUST** execute the following verification steps in sequence:
   - Formatting & Linting (`terraform fmt -check`, `tflint`)
   - Static Security Analysis (Gitleaks, Checkov)
   - Policy Compliance (Conftest)
   - Ephemeral Integration Testing (in isolated GCP test sandboxes)
3. **Branch Protection Enforced**: Pull Requests **MUST NOT** be merged to `main` unless all required CI pipeline status checks pass.

## References
* [Cloud Foundation Toolkit CI Workflows](https://github.com/GoogleCloudPlatform/cloud-foundation-toolkit/tree/master/.github/workflows)
* [Fabric Org Setup CI Integration](https://github.com/GoogleCloudPlatform/cloud-foundation-fabric/tree/master/fast/stages/0-org-setup)

## Consequences
* **Guaranteed Code Quality**: Prevents unformatted, non-compliant, or failing Terraform code from reaching the main branch.
* **Deterministic Release Pipeline**: Standardized, automated verification across all module releases.
