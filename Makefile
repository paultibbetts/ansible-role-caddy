.PHONY: setup deps requirements lint test test-%

GALAXY_FLAGS ?=

-include .env
export

setup:
	@command -v uv >/dev/null || \
		(echo "uv is not installed" && exit 1)
	uv sync

requirements: setup
	uv pip compile pyproject.toml --group dev -o requirements-dev.txt

deps: setup
	uv run ansible-galaxy collection install -r molecule/requirements.yml $(GALAXY_FLAGS)

requirements: setup
	uv pip compile pyproject.toml --universal --group dev -o requirements-dev.txt

lint: setup
	uv run ansible-lint .

test: setup deps
	uv run molecule test

test-%: setup deps
	uv run molecule test -s $*

