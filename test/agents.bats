#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  CHECK="${REPO_ROOT}/scripts/check-agents.sh"
  FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
}

@test "the declared agents have distinct names and uids" {
  run bash "${CHECK}" "${REPO_ROOT}/inventory"
  [ "${status}" -eq 0 ]
}

@test "duplicate agent uids are rejected" {
  run bash "${CHECK}" "${FIXTURES}/duplicate-uid"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"agent uids are not distinct"* ]]
}

@test "duplicate agent names are rejected" {
  run bash "${CHECK}" "${FIXTURES}/duplicate-name"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"agent names are not distinct"* ]]
}
