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
| `scripts/` | build and test logic the Makefile dispatches to |
| `docs/adrs/` | decisions that are fixed |
| `build/` | untouched tool reports, stamps and generated config, never committed |

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

Every quality tool runs as separate targets: the tool emits its native report untouched into
`build/`, and a `.checked` target in the Makefile reads the report in place and compares it against
the thresholds written in that recipe and against the counts in `stats.mk`, printing measured
against allowed. The comparison is inlined in the Makefile, not delegated to a script.

```
yamllint: files 24/20 errors 0/0 warnings 0/0
shellcheck: files 4/4 errors 0/0 warnings 0/0
bats: files 4/3 tests 27/14 failures 0/0
```

No report recipe absorbs a tool's exit status: a tool that finds something exits non-zero, its
report still lands on disk, and the build stops right there, before the corresponding `.checked`
target ever runs. Before any report is generated, `build/versions.txt` asks every tool for its
version, so a missing or broken install fails the build at once rather than leaving an empty
report that a check would read as clean. `test/makefile.bats` pins the first half of that: planting
one finding per tool shows the report lands and the build stops without reaching the check's
summary line.

`.checked` produces no file: the targets are phony, so the comparison — cheap by design — runs
every time rather than being trusted from a stamp. Coverage is asserted too, so a tool that
examined nothing fails rather than passes. The model is fixed by
[ADR 001](docs/adrs/001-report-threshold-check-build-model.md), matching how
[gettoken PR #50](https://github.com/thruput-io/gettoken/pull/50) settled the same question.

## Targets

| Target | Effect |
| --- | --- |
| `make setup` | install the pinned toolchain from `constants.env` |
| `make ci` | lint, schema and unit tests |
| `make container-test` | the same, inside the Debian container |
| `make integration-test` | run the playbook twice in a container, asserting idempotency |
| `make plan` | report drift, change nothing |
| `make apply` | reconcile the host |
| `make collection` | build the collection tarball into `build/` |
