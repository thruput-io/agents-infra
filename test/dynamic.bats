#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
}

@test "the generated config exposes the collection namespace and name" {
  run bash -c "cd '${REPO_ROOT}' && bash dynamic.sh"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"COLLECTION_NAMESPACE := thruput"* ]]
  [[ "${output}" == *"COLLECTION_NAME := local_runtime"* ]]
}

@test "the generated config exposes an install command and build deps" {
  run bash -c "cd '${REPO_ROOT}' && bash dynamic.sh"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"INSTALL_COMMAND := "* ]]
  [[ "${output}" == *"BUILD_DEPS := "* ]]
}

@test "the generated config exposes the debian build inputs on every platform" {
  run bash -c "cd '${REPO_ROOT}' && bash dynamic.sh"
  [ "${status}" -eq 0 ]
  [[ "${output}" == *"DEBIAN_TAG := trixie-slim"* ]]
  [[ "${output}" == *"CHECKMAKE_VERSION := v0.3.2"* ]]
}

@test "every generated line is a make assignment or a comment" {
  run bash -c "cd '${REPO_ROOT}' && bash dynamic.sh | grep -cvE '^(#| *[A-Z_]+ := )'"
  [ "${output}" -eq 0 ]
}
