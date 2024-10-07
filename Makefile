env_files := $(shell find . -type f \( -name "*.env.mine" -o -name "*.env.public" -o -name "*.env.test" \) | sort -r)

ifneq ($(strip $(env_files)),)
    include $(env_files)
    export $(shell sed 's/=.*//' $(env_files))
endif

GO := "go"
ENV_VARS := $(shell sed 's/=.*//' $(env_files) | sort -u)
CURRENT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
CMD_DIR := cmd
CMDS := $(wildcard $(CMD_DIR)/*)
BINARIES := $(patsubst $(CMD_DIR)/%,bin/%,$(CMDS))

.PHONY: all build clean dump help

# HELP - will output the help for each task in the Makefile
# In sorted order.
# The width of the first column can be determined by the `width` value passed to awk
#
# thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html for the initial version.
#
help: ## This help.
	@grep -E -h "^[a-zA-Z_-]+:.*?## " $(MAKEFILE_LIST) \
	  | sort \
	  | awk -v width=20 'BEGIN {FS = ":.*?## "} {printf "\033[36m%-*s\033[0m %s\n", width, $$1, $$2}'

all: @build ## Build all binaries.

$(BINARIES): bin/%: $(CMD_DIR)/%
	@$(GO) build -o $@ ./$<

build: clean ## Clean and build all binaries.
	@$(MAKE) $(BINARIES)

clean: ## Clean up built binaries.
	@$(GO) clean
	@rm -f bin/*

dump: ## Dump environment variables and current branch information.
	@echo "----------------------"
	@echo "\033[32m.env File Contents\033[0m"
	@echo "----------------------"
	@$(MAKE) print_env_var_files
	@echo "----------------------"
	@echo "\033[32mMakefile Env Values\033[0m"
	@echo "----------------------"
	@$(MAKE) print_makefile_env_vars
	@echo "----------------------"
	@echo "\033[32mBranch Data\033[0m"
	@echo "----------------------"
	@echo "\033[36mCurrent Branch\033[0m $(CURRENT_BRANCH)"
	@echo "----------------------"
	@echo "\033[32mBinary Targets\033[0m"
	@echo "----------------------"
	@echo "$(BINARIES)"
	@echo "----------------------"

print_makefile_env_vars:
	@for var_name in $(ENV_VARS); do \
		echo "\033[36m$$var_name\033[0m=$${!var_name}"; \
	done

print_env_var_files: ## Print the environment variables stored in all env_files
	@for file in $(env_files); do \
		echo "\033[33m$$file\033[0m"; \
		while IFS='=' read -r key value || [ -n "$$key" ]; do \
			if [ "$${key:0:1}" != "#" ] && [ -n "$$key" ]; then \
				echo "\033[36m$$key\033[0m=$$value"; \
			fi; \
		done < $$file; \
	done

test: ## Run all tests.
	@$(GO) test ./...

todos: ## dump todos and their file
	paths to stdout (todos in test files ignored, see make todos-all)
	find . -type f -name "*.*" -not -path "**/*_test.go" -not -path "**/.git/**" -not -path "**/.idea/**" -exec grep -iIH todo {} \; | column -t -s:

todos-all: ## dump todos and their file paths to stdout
	find . -type f -name "*.*" -not -path "**/.git/**" -not -path "**/.idea/**" -exec grep -iIH todo {} \; | column -t -s:

reset: clean build ## Clean and build binaries.
