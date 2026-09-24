#!/usr/bin/env bash
set -euo pipefail

inventory=test/fixtures/container
playbook=src/playbooks/local-runtime.yml

ansible-playbook -i "$inventory" "$playbook"

second_run=$(ansible-playbook -i "$inventory" "$playbook" | tee /dev/stderr)
changed=$(grep -oE 'changed=[0-9]+' <<<"$second_run" | tail -1 | cut -d= -f2)

if [ "$changed" -ne 0 ]; then
  echo "second run was not idempotent: changed=$changed" >&2
  exit 1
fi

for agent in tore rasmus paula; do
  id "$agent" >/dev/null
done

stat -c '%a %G' /srv/workspace
