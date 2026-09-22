# 1. Pure Terraform Provider Project

* **Status**: Accepted
* **Date**: 2026-07-23

## Context
This repository provides agent setup components (identities, service accounts, secrets access, mailboxes, and resource tags) for Google Cloud FAST.

## Decision
This repository functions as a **pure resource provider project** containing reusable Terraform modules consumed directly by state-holding FAST stages. Modules MUST NOT include backend configuration blocks (`backend "gcs"`).

## References
* [Google Cloud Best Practices for Terraform](https://cloud.google.com/docs/terraform/best-practices/general-style-structure)

## Consequences
* **Statelessness**: This repository does not handle or persist production Terraform state.
* **Reusability**: Downstream FAST stages reference and include these modules directly via GitHub source URLs.
