ROOT_DIR    := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
IMAGE       := agents-infra-build
PLAYBOOK    := src/playbooks/local-runtime.yml
INVENTORY   := inventory
SCHEMA_FILE := src/schemas/agents.schema.json
AGENTS_FILE := inventory/group_vars/all/agents.yml
YAML_FILES  := $(shell find src inventory test .github -type f \( -name '*.yml' -o -name '*.yaml' \))
SHELL_FILES := dynamic.sh $(shell find scripts -type f -name '*.sh')
BATS_FILES  := $(shell find test -type f -name '*.bats')
MAKE_FILES  := Makefile

-include build/config.mk
include stats.mk

.PHONY: all clean ci config setup stats image container-test integration-test collection lint lint-yaml lint-shell lint-make lint-ansible schema test coverage plan apply \
        build/yamllint.checked build/shellcheck.checked build/checkmake.checked build/ansible-lint.checked build/schema.checked build/bats.checked build/kcov.checked build/lint.checked

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

build/versions.txt: | build
	bash scripts/versions.sh > build/versions.txt

build/yamllint-report.txt: $(YAML_FILES) .yamllint build/versions.txt
	yamllint -f parsable src inventory test .github > build/yamllint-report.txt

build/shellcheck-report.xml: $(SHELL_FILES) build/versions.txt
	shellcheck -x --format=checkstyle dynamic.sh scripts/*.sh > build/shellcheck-report.xml

build/checkmake-report.json: $(MAKE_FILES) stats.mk build/versions.txt
	checkmake -o json Makefile > build/checkmake-report.json

build/ansible-lint-report.sarif: $(YAML_FILES) build/versions.txt
	ansible-lint --strict -f sarif src/playbooks/local-runtime.yml > build/ansible-lint-report.sarif

build/schema-report.json: $(SCHEMA_FILE) $(AGENTS_FILE) build/versions.txt
	check-jsonschema --output-format json --schemafile src/schemas/agents.schema.json inventory/group_vars/all/agents.yml > build/schema-report.json

build/report.xml: $(BATS_FILES) $(SHELL_FILES) $(AGENTS_FILE) build/versions.txt
	bats --formatter tap --report-formatter junit --output build test

build/coverage/bats/coverage.json: $(BATS_FILES) $(SHELL_FILES) build/versions.txt
	kcov --include-path=scripts,dynamic.sh build/coverage bats test

build/yamllint.checked: build/yamllint-report.txt Makefile
	set -euo pipefail; errors=$$(awk '/\[error\]/{n++} END{print n+0}' build/yamllint-report.txt); warnings=$$(awk '/\[warning\]/{n++} END{print n+0}' build/yamllint-report.txt); \
	echo "yamllint: files $(YAML_FILE_COUNT)/20 errors $$errors/0 warnings $$warnings/0"; \
	[ $(YAML_FILE_COUNT) -ge 20 ] && [ $$errors -le 0 ] && [ $$warnings -le 0 ]

build/shellcheck.checked: build/shellcheck-report.xml Makefile
	set -euo pipefail; files=$$(xmlstarlet sel -t -v 'count(//file)' build/shellcheck-report.xml); errors=$$(xmlstarlet sel -t -v 'count(//error[@severity="error"])' build/shellcheck-report.xml); warnings=$$(xmlstarlet sel -t -v 'count(//error[@severity="warning"])' build/shellcheck-report.xml); \
	echo "shellcheck: files $$files/$(SHELL_FILE_COUNT) errors $$errors/0 warnings $$warnings/0"; \
	[ $$files -eq $(SHELL_FILE_COUNT) ] && [ $$errors -le 0 ] && [ $$warnings -le 0 ]

build/checkmake.checked: build/checkmake-report.json Makefile
	set -euo pipefail; errors=$$(jq -s 'flatten | length' build/checkmake-report.json); \
	echo "checkmake: files $(MAKE_FILE_COUNT)/1 errors $$errors/0"; \
	[ $(MAKE_FILE_COUNT) -ge 1 ] && [ $$errors -le 0 ]

build/ansible-lint.checked: build/ansible-lint-report.sarif Makefile
	set -euo pipefail; errors=$$(jq '[.runs[].results[] | select(.level == "error")] | length' build/ansible-lint-report.sarif); warnings=$$(jq '[.runs[].results[] | select(.level == "warning")] | length' build/ansible-lint-report.sarif); \
	echo "ansible-lint: files $(PLAYBOOK_COUNT)/1 errors $$errors/0 warnings $$warnings/0"; \
	[ $(PLAYBOOK_COUNT) -ge 1 ] && [ $$errors -le 0 ] && [ $$warnings -le 0 ]

build/schema.checked: build/schema-report.json Makefile
	set -euo pipefail; errors=$$(jq '.errors | length' build/schema-report.json); \
	echo "schema: files $(SCHEMA_COUNT)/1 errors $$errors/0"; \
	[ $(SCHEMA_COUNT) -ge 1 ] && [ $$errors -le 0 ]

build/bats.checked: build/report.xml Makefile
	set -euo pipefail; tests=$$(xmlstarlet sel -t -v 'count(//testcase)' build/report.xml); failures=$$(xmlstarlet sel -t -v 'count(//testcase/failure)' build/report.xml); \
	echo "bats: files $(BATS_FILE_COUNT)/3 tests $$tests/14 failures $$failures/0"; \
	[ $(BATS_FILE_COUNT) -ge 3 ] && [ $$tests -ge 14 ] && [ $$failures -eq 0 ]

build/kcov.checked: build/coverage/bats/coverage.json Makefile
	set -euo pipefail; files=$$(jq '.files | length' build/coverage/bats/coverage.json); coverage=$$(jq -r '.percent_covered | tonumber | floor' build/coverage/bats/coverage.json); \
	echo "kcov: files $$files/2 coverage $$coverage/85"; \
	[ $$files -ge 2 ] && [ $$coverage -ge 85 ]

build/lint.checked: build/yamllint.checked build/shellcheck.checked build/checkmake.checked build/ansible-lint.checked
	@echo "lint: all quality gates passed"

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
