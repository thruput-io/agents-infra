#!/usr/bin/env bash
set -euo pipefail

inventory=${1:?inventory directory required}

agents=$(ansible-inventory -i "$inventory" --list | jq -c '._meta.hostvars.localhost.agents')

assert_distinct() {
  local field=$1
  local values total distinct
  values=$(jq -c "[.[].${field}]" <<<"$agents")
  total=$(jq 'length' <<<"$values")
  distinct=$(jq 'unique | length' <<<"$values")

  if [ "$total" -ne "$distinct" ]; then
    echo "agent ${field}s are not distinct: $values" >&2
    exit 1
  fi
}

assert_distinct name
