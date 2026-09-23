# Agents Runtime

This repo contains IaC for running agent workloads.

Local machine first, targeting macOS, in the style of the `gettoken` repo:
agent workloads run as an unprivileged OS user, separate from the privileged
account that holds credentials.

The single most important objective: always be in a runnable state. No
half-built increments.

## Model

Agent accounts and the shared collaboration surface are declared once, as data,
and reconciled with Ansible. There is no state file: actual state is read from
the machine on every run, so drift is detected rather than assumed.

`make plan` reports drift and changes nothing. `make apply` reconciles.

## Layout

| Path | Contents |
| --- | --- |
| `src/` | the `thruput.local_runtime` collection: roles and playbook |
| `src/schemas/` | the schemas every site document is parsed against |
| `inventory/` | site data — which agents exist, which paths are shared |
| `test/` | bats unit tests and container fixtures |
| `scripts/` | logic the Makefile dispatches to |
| `thresholds.json` | the permitted error, warning and test counts |
| `docs/adrs/` | decisions that are fixed |
| `build/<platform>/` | untouched tool reports, stamps and generated config, never committed |

## Desired state

Agents are declared as a list in `inventory/group_vars/all/agents.yml`:

```yaml
agents:
  - name: paula
    uid: 505
    real_name: Agent Paula
    shell: /bin/zsh
```

The schema constrains uids to the 501-999 range, requires posix login names,
rejects unknown properties, and rejects identical entries.

JSON Schema has no unique-by-property keyword, so a repeated name carrying a
different uid passes the schema. `scripts/check-agents.sh` closes that gap by
rejecting duplicate names and duplicate uids, and `test/schema.bats` pins the
boundary between the two.

## Privileges

Agent accounts cannot reconcile themselves. Creating accounts needs root, and
Homebrew on the shared host is owned by the privileged account. Consequently:

- `make ci`, `make container-test` and `make integration-test` run in a
  container and need no host privileges.
- `make setup` and `make apply` must be run by the privileged account.

## Build model

Every quality tool runs as three separate targets: the tool emits its native report untouched into
`build/<platform>/`, `thresholds.json` declares what is permitted, and a `.checked` target compares
the report against those thresholds and against the counts in `stats.mk`, printing measured against
allowed.

```
yamllint: 24 files declared, not reported enumerated, 0 errors (allowed 0), 0 warnings (allowed 0)
shellcheck: 8 files declared, 8 enumerated, 0 errors (allowed 0), 0 warnings (allowed 0)
bats: 10 tests across 2 files, 0 failures, minimum 10
```

A `.checked` stamp means a comparison passed, never that a command ran. Coverage is asserted too,
so a tool that examined nothing fails rather than passes. The model is fixed by
[ADR 001](docs/adrs/001-report-threshold-check-build-model.md).

## Targets

| Target | Effect |
| --- | --- |
| `make setup` | install the pinned toolchain from `constants.env` |
| `make ci` | lint, schema and unit tests |
| `make container-test` | the same, inside the Debian container |
| `make integration-test` | run the playbook twice in a container, asserting idempotency |
| `make plan` | report drift, change nothing |
| `make apply` | reconcile the host |
| `make collection` | build the collection tarball into `build/<platform>/` |
