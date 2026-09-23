ROOT_DIR    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
IMAGE       := agents-infra-build
THRESHOLDS  := thresholds.json
PLAYBOOK    := src/playbooks/local-runtime.yml
INVENTORY   := inventory
SCHEMA_FILE := src/schemas/agents.schema.json
AGENTS_FILE := inventory/group_vars/all/agents.yml
YAML_FILES  := $(shell find src inventory test .github -type f \( -name '*.yml' -o -name '*.yaml' \))
SHELL_FILES := dynamic.sh $(shell find scripts -type f -name '*.sh')
BATS_FILES  := $(shell find test -type f -name '*.bats')
MAKE_FILES  := Makefile

YAMLLINT_ERRORS       = $(shell awk 'BEGIN{n=0} /\[error\]/{n++} END{print n}' build/yamllint-report.txt)
YAMLLINT_WARNINGS     = $(shell awk 'BEGIN{n=0} /\[warning\]/{n++} END{print n}' build/yamllint-report.txt)
SHELLCHECK_FILES      = $(shell xmlstarlet sel -t -v 'count(//file)' build/shellcheck-report.xml)
SHELLCHECK_ERRORS     = $(shell xmlstarlet sel -t -v 'count(//error[@severity="error"])' build/shellcheck-report.xml)
SHELLCHECK_WARNINGS   = $(shell xmlstarlet sel -t -v 'count(//error[@severity="warning"])' build/shellcheck-report.xml)
CHECKMAKE_ERRORS      = $(shell jq -s 'flatten | length' build/checkmake-report.json)
ANSIBLELINT_ERRORS    = $(shell jq '[.runs[].results[] | select(.level == "error")] | length' build/ansible-lint-report.sarif)
ANSIBLELINT_WARNINGS  = $(shell jq '[.runs[].results[] | select(.level == "warning")] | length' build/ansible-lint-report.sarif)
SCHEMA_ERRORS         = $(shell jq '.errors | length' build/schema-report.json)
BATS_TESTS            = $(shell xmlstarlet sel -t -v 'count(//testcase)' build/report.xml)
BATS_FAILURES         = $(shell xmlstarlet sel -t -v 'count(//testcase/failure)' build/report.xml)
KCOV_COVERAGE         = $(shell jq -r '.percent_covered | tonumber | floor' build/coverage/kcov-merged/coverage.json)
KCOV_FILES            = $(shell jq '.files | length' build/coverage/kcov-merged/coverage.json)

YAMLLINT_ERRORS_MAX      := $(shell jq -r '."yamllint".errors' thresholds.json)
YAMLLINT_WARNINGS_MAX    := $(shell jq -r '."yamllint".warnings' thresholds.json)
YAMLLINT_FILES_MIN       := $(shell jq -r '."yamllint".min_files' thresholds.json)
SHELLCHECK_ERRORS_MAX    := $(shell jq -r '."shellcheck".errors' thresholds.json)
SHELLCHECK_WARNINGS_MAX  := $(shell jq -r '."shellcheck".warnings' thresholds.json)
SHELLCHECK_FILES_MIN     := $(shell jq -r '."shellcheck".min_files' thresholds.json)
CHECKMAKE_ERRORS_MAX     := $(shell jq -r '."checkmake".errors' thresholds.json)
CHECKMAKE_FILES_MIN      := $(shell jq -r '."checkmake".min_files' thresholds.json)
ANSIBLELINT_ERRORS_MAX   := $(shell jq -r '."ansible-lint".errors' thresholds.json)
ANSIBLELINT_WARNINGS_MAX := $(shell jq -r '."ansible-lint".warnings' thresholds.json)
ANSIBLELINT_FILES_MIN    := $(shell jq -r '."ansible-lint".min_files' thresholds.json)
SCHEMA_ERRORS_MAX        := $(shell jq -r '."schema".errors' thresholds.json)
SCHEMA_FILES_MIN         := $(shell jq -r '."schema".min_files' thresholds.json)
BATS_TESTS_MIN           := $(shell jq -r '."bats".min_tests' thresholds.json)
BATS_FILES_MIN           := $(shell jq -r '."bats".min_files' thresholds.json)
KCOV_COVERAGE_MIN        := $(shell jq -r '."kcov".min_coverage' thresholds.json)
KCOV_FILES_MIN           := $(shell jq -r '."kcov".min_files' thresholds.json)

-include build/config.mk
include stats.mk

.PHONY: all clean ci config setup stats image container-test integration-test collection lint lint-yaml lint-shell lint-make lint-ansible schema test coverage plan apply

all:          ci
ci:           lint schema test coverage stats
config:       build/config.mk
setup:        build/setup.txt
stats:        build/stats.txt
image:        build/image.txt
collection:   build/collection.txt
lint:         build/lint.checked
lint-yaml:    build/yamllint.checked
lint-shell:   build/shellcheck.checked
lint-make:    build/checkmake.checked
lint-ansible: build/ansible-lint.checked
schema:       build/schema.checked
test:         build/bats.checked
coverage:     build/kcov.checked

build:
	mkdir -p build

build/config.mk: dynamic.sh constants.env | build
	bash dynamic.sh > build/config.mk

build/setup.txt: build/config.mk
	bash -ec "$(INSTALL_COMMAND) $(BUILD_DEPS)"
	echo "$(BUILD_DEPS)" > build/setup.txt

build/yamllint-report.txt: $(YAML_FILES) .yamllint | build
	yamllint -f parsable src inventory test .github > build/yamllint-report.txt

build/shellcheck-report.xml: $(SHELL_FILES) | build
	shellcheck -x --format=checkstyle dynamic.sh scripts/*.sh > build/shellcheck-report.xml

build/checkmake-report.json: $(MAKE_FILES) stats.mk | build
	checkmake -o json Makefile > build/checkmake-report.json

build/ansible-lint-report.sarif: $(YAML_FILES) | build
	ansible-lint --strict -f sarif src/playbooks/local-runtime.yml > build/ansible-lint-report.sarif

build/schema-report.json: $(SCHEMA_FILE) $(AGENTS_FILE) | build
	check-jsonschema --output-format json --schemafile src/schemas/agents.schema.json inventory/group_vars/all/agents.yml > build/schema-report.json

build/report.xml: $(BATS_FILES) $(SHELL_FILES) $(AGENTS_FILE) | build
	bats --formatter tap --report-formatter junit --output build test

build/coverage/kcov-merged/coverage.json: $(BATS_FILES) $(SHELL_FILES) | build
	kcov --include-path=scripts,dynamic.sh build/coverage-raw bats test
	kcov --merge build/coverage build/coverage-raw

build/kcov.checked: build/coverage/kcov-merged/coverage.json $(THRESHOLDS)
	echo "kcov: files $(KCOV_FILES)/$(KCOV_FILES_MIN) coverage $(KCOV_COVERAGE)/$(KCOV_COVERAGE_MIN)"
	[ $(KCOV_FILES) -ge $(KCOV_FILES_MIN) ] && [ $(KCOV_COVERAGE) -ge $(KCOV_COVERAGE_MIN) ]
	echo checked > build/kcov.checked

build/yamllint.checked: build/yamllint-report.txt $(THRESHOLDS)
	echo "yamllint: files $(YAML_FILE_COUNT)/$(YAMLLINT_FILES_MIN) errors $(YAMLLINT_ERRORS)/$(YAMLLINT_ERRORS_MAX) warnings $(YAMLLINT_WARNINGS)/$(YAMLLINT_WARNINGS_MAX)"
	[ $(YAML_FILE_COUNT) -ge $(YAMLLINT_FILES_MIN) ] && [ $(YAMLLINT_ERRORS) -le $(YAMLLINT_ERRORS_MAX) ] && [ $(YAMLLINT_WARNINGS) -le $(YAMLLINT_WARNINGS_MAX) ]
	echo checked > build/yamllint.checked
build/shellcheck.checked: build/shellcheck-report.xml $(THRESHOLDS)
	echo "shellcheck: files $(SHELLCHECK_FILES)/$(SHELL_FILE_COUNT) errors $(SHELLCHECK_ERRORS)/$(SHELLCHECK_ERRORS_MAX) warnings $(SHELLCHECK_WARNINGS)/$(SHELLCHECK_WARNINGS_MAX)"
	[ $(SHELLCHECK_FILES) -eq $(SHELL_FILE_COUNT) ] && [ $(SHELLCHECK_ERRORS) -le $(SHELLCHECK_ERRORS_MAX) ] && [ $(SHELLCHECK_WARNINGS) -le $(SHELLCHECK_WARNINGS_MAX) ]
	echo checked > build/shellcheck.checked

build/checkmake.checked: build/checkmake-report.json $(THRESHOLDS)
	echo "checkmake: files $(MAKE_FILE_COUNT)/$(CHECKMAKE_FILES_MIN) errors $(CHECKMAKE_ERRORS)/$(CHECKMAKE_ERRORS_MAX)"
	[ $(MAKE_FILE_COUNT) -ge $(CHECKMAKE_FILES_MIN) ] && [ $(CHECKMAKE_ERRORS) -le $(CHECKMAKE_ERRORS_MAX) ]
	echo checked > build/checkmake.checked

build/ansible-lint.checked: build/ansible-lint-report.sarif $(THRESHOLDS)
	echo "ansible-lint: files $(PLAYBOOK_COUNT)/$(ANSIBLELINT_FILES_MIN) errors $(ANSIBLELINT_ERRORS)/$(ANSIBLELINT_ERRORS_MAX) warnings $(ANSIBLELINT_WARNINGS)/$(ANSIBLELINT_WARNINGS_MAX)"
	[ $(PLAYBOOK_COUNT) -ge $(ANSIBLELINT_FILES_MIN) ] && [ $(ANSIBLELINT_ERRORS) -le $(ANSIBLELINT_ERRORS_MAX) ] && [ $(ANSIBLELINT_WARNINGS) -le $(ANSIBLELINT_WARNINGS_MAX) ]
	echo checked > build/ansible-lint.checked

build/schema.checked: build/schema-report.json $(THRESHOLDS)
	echo "schema: files $(SCHEMA_COUNT)/$(SCHEMA_FILES_MIN) errors $(SCHEMA_ERRORS)/$(SCHEMA_ERRORS_MAX)"
	[ $(SCHEMA_COUNT) -ge $(SCHEMA_FILES_MIN) ] && [ $(SCHEMA_ERRORS) -le $(SCHEMA_ERRORS_MAX) ]
	echo checked > build/schema.checked

build/bats.checked: build/report.xml $(THRESHOLDS)
	echo "bats: files $(BATS_FILE_COUNT)/$(BATS_FILES_MIN) tests $(BATS_TESTS)/$(BATS_TESTS_MIN) failures $(BATS_FAILURES)/0"
	[ $(BATS_FILE_COUNT) -ge $(BATS_FILES_MIN) ] && [ $(BATS_TESTS) -ge $(BATS_TESTS_MIN) ] && [ $(BATS_FAILURES) -eq 0 ]
	echo checked > build/bats.checked

build/lint.checked: build/yamllint.checked build/shellcheck.checked build/checkmake.checked build/ansible-lint.checked
	echo checked > build/lint.checked

build/image.txt: scripts/docker/Dockerfile scripts/build-image.sh constants.env | build
	bash scripts/build-image.sh $(IMAGE)
	echo "$(IMAGE)" > build/image.txt

build/collection.txt: $(YAML_FILES) src/galaxy.yml | build
	ansible-galaxy collection build src --output-path build --force
	echo "$(COLLECTION_NAMESPACE)-$(COLLECTION_NAME)" > build/collection.txt

container-test: build/image.txt
	docker run --rm --user $(shell id -u):$(shell id -g) -e HOME=/tmp -e USER=$(shell id -un) -v $(ROOT_DIR):/work -w /work $(IMAGE) make -B ci

integration-test: build/image.txt
	docker run --rm -v $(ROOT_DIR):/work -w /work $(IMAGE) bash scripts/integration-test.sh

plan:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --check --diff

apply:
	ansible-playbook -i $(INVENTORY) $(PLAYBOOK) --diff

clean:
	rm -rf build
