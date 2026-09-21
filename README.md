# Agents Runtime

This repo contains IaC for running agent workloads.

Local machine first, targeting macOS, in the style of the `gettoken` repo:
agent workloads run as an unprivileged OS user, separate from the privileged
account that holds credentials. 

The single most important objective: always be in a runnable state. No
half-built increments.
