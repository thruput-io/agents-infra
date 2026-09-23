#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  SCHEMA="${REPO_ROOT}/src/schemas/agents.schema.json"
  FIXTURES="${BATS_TEST_DIRNAME}/fixtures"
}

@test "the agents document conforms to the schema" {
  run check-jsonschema --schemafile "${SCHEMA}" "${REPO_ROOT}/inventory/group_vars/all/agents.yml"
  [ "${status}" -eq 0 ]
}

@test "an agent missing uid is rejected" {
  run check-jsonschema --schemafile "${SCHEMA}" "${FIXTURES}/missing-uid.yml"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"'uid' is a required property"* ]]
}

@test "an unknown agent property is rejected" {
  run check-jsonschema --schemafile "${SCHEMA}" "${FIXTURES}/unknown-property.yml"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"Additional properties are not allowed"* ]]
}

@test "a uid below the agent range is rejected" {
  run check-jsonschema --schemafile "${SCHEMA}" "${FIXTURES}/uid-below-range.yml"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"less than the minimum of 501"* ]]
}

@test "a name that is not a posix login name is rejected" {
  run check-jsonschema --schemafile "${SCHEMA}" "${FIXTURES}/bad-name.yml"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"does not match"* ]]
}

@test "two identical agent entries are rejected" {
  run check-jsonschema --schemafile "${SCHEMA}" "${FIXTURES}/identical-agents.yml"
  [ "${status}" -ne 0 ]
  [[ "${output}" == *"has non-unique elements"* ]]
}

@test "the schema alone cannot reject a repeated name carrying a different uid" {
  run check-jsonschema --schemafile "${SCHEMA}" "${FIXTURES}/same-name-different-uid.yml"
  [ "${status}" -eq 0 ]
}
