YAML_FILE_COUNT  := $(words $(YAML_FILES))
SHELL_FILE_COUNT := $(words $(SHELL_FILES))
SCHEMA_COUNT     := $(words $(SCHEMA_FILE))
PLAYBOOK_COUNT   := $(words $(PLAYBOOK))
MAKE_FILE_COUNT  := $(words $(MAKE_FILES))
BATS_FILE_COUNT  := $(words $(BATS_FILES))
ROLE_COUNT       := $(words $(wildcard src/roles/*))

build/stats.txt: $(YAML_FILES) $(SHELL_FILES) $(BATS_FILES) | build
	{ \
	  echo "yaml files: $(YAML_FILE_COUNT)"; \
	  echo "shell files: $(SHELL_FILE_COUNT)"; \
	  echo "json schemas: $(SCHEMA_COUNT)"; \
	  echo "playbooks: $(PLAYBOOK_COUNT)"; \
	  echo "makefiles: $(MAKE_FILE_COUNT)"; \
	  echo "bats files: $(BATS_FILE_COUNT)"; \
	  echo "roles: $(ROLE_COUNT)"; \
	} > build/stats.txt
