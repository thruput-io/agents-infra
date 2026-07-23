# 1. Pure Terraform Provider Project

* **Status**: Accepted
* **Date**: 2026-07-23

## Context
This repository is designed to support Google Cloud FAST installations by providing agent setup components (service accounts, identities, secrets access, mailboxes, and resource tags).

Google Cloud Foundation Fabric (FAST) enforces a clear architectural boundary between **stateless composable modules** and **state-holding execution stages**.

## Decision
This repository will function as a **pure resource provider project** containing reusable Terraform modules. 

All modules in this repository MUST be strictly stateless (containing no `backend` or provider credential blocks inside module definitions).

The actual state-holding infrastructure projects provided by FAST setups will consume and include these modules directly via GitHub source URLs.

## Consequences
* **Statelessness**: This repository does not handle or persist production Terraform state. State created during integration testing is transient and discarded upon test completion.
* **Reusability & Decoupling**: Downstream FAST stages can reference and include these modules directly (`github.com/johgr814/agents-infra//modules/...`) without state lock-in.
* **FAST Compliance**: Module interfaces follow FAST contracts and variable conventions.
