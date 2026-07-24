# 1. Pure Terraform Provider Project

* **Status**: Accepted
* **Date**: 2026-07-23

## Context
This repository is designed to support the Google Cloud FAST installation by providing agent setup components (identities, service accounts, secrets access, mailboxes, and resource tags).

## Decision
This repository will function as a **pure resource provider project** containing reusable Terraform modules.

The actual state-holding infrastructure projects provided by the FAST setup will consume and include these modules directly. Module definitions inside this repository MUST NOT include backend configuration blocks (`backend "gcs"`) or persistent state configuration, adhering to FAST module interface standards.

## Consequences
* **Statelessness**: This repository does not handle or persist production Terraform state (state is created for testing purposes only and discarded).
* **Reusability**: Downstream FAST stages can reference and include these modules directly via GitHub source URLs (e.g., `github.com/johgr814/agents-infra//modules/...`).
