SHELL := /bin/bash
SCRIPT := gentoo-system-maintenance.sh

.PHONY: check lint test

check: lint test

lint:
	bash -n $(SCRIPT)
	@if command -v shellcheck >/dev/null 2>&1; then shellcheck -x -S warning $(SCRIPT); else echo "shellcheck not installed, skipping"; fi

test:
	bash tests/static.sh ./$(SCRIPT)
	bash tests/smoke.sh ./$(SCRIPT)
	bash tests/docs.sh
	bash tests/assets.sh

container-test:
	bash tests/emerge_runtime.sh
	bash tests/preview_failure.sh
