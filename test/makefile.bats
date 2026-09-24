#!/usr/bin/env bats

setup() {
  REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/.." && pwd)"
  COPY="${BATS_TEST_TMPDIR}/repo"
  mkdir "${COPY}"
  tar -C "${REPO_ROOT}" --exclude=./build --exclude=./.git --exclude=./test/makefile.bats -cf - . | tar -C "${COPY}" -xf -
}

plant_yaml_error() {
  printf -- '---\nkey: value   \n' > "${COPY}/inventory/trailing-spaces.yml"
}

plant_shell_error() {
  printf 'echo hi\n' > "${COPY}/scripts/no-shebang.sh"
}

plant_make_error() {
  printf 'long:\n\techo 1\n\techo 2\n\techo 3\n\techo 4\n\techo 5\n\techo 6\n' >> "${COPY}/Makefile"
}

plant_playbook_error() {
  printf -- '---\n- hosts: all\n  gather_facts: true\n' > "${COPY}/src/playbooks/local-runtime.yml"
}

plant_schema_error() {
  printf -- '---\nagents:\n  - name: paula\n    uid: 5\n    real_name: Agent Paula\n    shell: /bin/zsh\n' > "${COPY}/inventory/group_vars/all/agents.yml"
}

plant_failing_test() {
  printf '#!/usr/bin/env bats\n\n@test "planted failure" {\n  false\n}\n' > "${COPY}/test/planted.bats"
}

link_every_tool() {
  mkdir "${COPY}/bin"
  for tool in make which mkdir bash find uname tr \
              yamllint shellcheck checkmake ansible-lint ansible-playbook ansible-inventory \
              check-jsonschema bats kcov xmlstarlet jq awk; do
    ln -s "$(command -v "$tool")" "${COPY}/bin/$tool"
  done
}

break_tool() {
  rm -f "${COPY}/bin/$1"
  printf '#!/bin/sh\nexit 1\n' > "${COPY}/bin/$1"
  chmod 755 "${COPY}/bin/$1"
}

@test "versions: every tool on PATH passes the gate and prints its own version" {
  link_every_tool
  run env PATH="${COPY}/bin" make -C "${COPY}" build/versions.txt
  [ "${status}" -eq 0 ]
  [[ "$(cat "${COPY}/build/versions.txt")" == *"yamllint"* ]]
  [[ "$(cat "${COPY}/build/versions.txt")" == *"kcov"* ]]
}

@test "versions: a tool absent from PATH fails before any report is written" {
  link_every_tool
  rm "${COPY}/bin/yamllint"
  run env PATH="${COPY}/bin" make -C "${COPY}" build/yamllint.checked
  [ "${status}" -ne 0 ]
  [ ! -e "${COPY}/build/yamllint-report.txt" ]
}

@test "versions: a tool present but broken fails before any report is written" {
  link_every_tool
  break_tool checkmake
  run env PATH="${COPY}/bin" make -C "${COPY}" build/yamllint.checked
  [ "${status}" -ne 0 ]
  [ ! -e "${COPY}/build/yamllint-report.txt" ]
}

@test "yamllint: a finding lands in the report even though the build stops there" {
  plant_yaml_error
  run make -C "${COPY}" build/yamllint-report.txt
  [ "${status}" -ne 0 ]
  [ "$(grep -c '\[error\]' "${COPY}/build/yamllint-report.txt")" -eq 1 ]
}

@test "yamllint: a finding stops the build before the check's summary line" {
  plant_yaml_error
  run make -C "${COPY}" build/yamllint.checked
  [ "${status}" -ne 0 ]
  [[ "${output}" != *"errors 1/0"* ]]
}

@test "shellcheck: a finding lands in the report even though the build stops there" {
  plant_shell_error
  run make -C "${COPY}" build/shellcheck-report.xml
  [ "${status}" -ne 0 ]
  [ "$(xmlstarlet sel -t -v 'count(//error[@severity="error"])' "${COPY}/build/shellcheck-report.xml")" -eq 1 ]
}

@test "shellcheck: a finding stops the build before the check's summary line" {
  plant_shell_error
  run make -C "${COPY}" build/shellcheck.checked
  [ "${status}" -ne 0 ]
  [[ "${output}" != *"errors 1/0"* ]]
}

@test "checkmake: a finding lands in the report even though the build stops there" {
  plant_make_error
  run make -C "${COPY}" build/checkmake-report.json
  [ "${status}" -ne 0 ]
  [ "$(jq -s 'flatten | length' "${COPY}/build/checkmake-report.json")" -eq 1 ]
}

@test "checkmake: a finding stops the build before the check's summary line" {
  plant_make_error
  run make -C "${COPY}" build/checkmake.checked
  [ "${status}" -ne 0 ]
  [[ "${output}" != *"errors 1/0"* ]]
}

@test "ansible-lint: a finding lands in the report even though the build stops there" {
  plant_playbook_error
  run make -C "${COPY}" build/ansible-lint-report.sarif
  [ "${status}" -ne 0 ]
  [ "$(jq '[.runs[].results[] | select(.level == "error")] | length' "${COPY}/build/ansible-lint-report.sarif")" -eq 1 ]
}

@test "ansible-lint: a finding stops the build before the check's summary line" {
  plant_playbook_error
  run make -C "${COPY}" build/ansible-lint.checked
  [ "${status}" -ne 0 ]
  [[ "${output}" != *"errors 1/0"* ]]
}

@test "schema: a finding lands in the report even though the build stops there" {
  plant_schema_error
  run make -C "${COPY}" build/schema-report.json
  [ "${status}" -ne 0 ]
  [ "$(jq '.errors | length' "${COPY}/build/schema-report.json")" -eq 1 ]
}

@test "schema: a finding stops the build before the check's summary line" {
  plant_schema_error
  run make -C "${COPY}" build/schema.checked
  [ "${status}" -ne 0 ]
  [[ "${output}" != *"errors 1/0"* ]]
}

@test "bats: a failing test lands in the report even though the build stops there" {
  plant_failing_test
  run make -C "${COPY}" build/report.xml
  [ "${status}" -ne 0 ]
  [ "$(xmlstarlet sel -t -v 'count(//testcase/failure)' "${COPY}/build/report.xml")" -eq 1 ]
}

@test "bats: a failing test stops the build before the check's summary line" {
  plant_failing_test
  run make -C "${COPY}" build/bats.checked
  [ "${status}" -ne 0 ]
  [[ "${output}" != *"failures 1/0"* ]]
}

@test ".checked leaves no stamp file whether it passes or fails" {
  run make -C "${COPY}" build/schema.checked
  [ "${status}" -eq 0 ]
  [ ! -e "${COPY}/build/schema.checked" ]
}
