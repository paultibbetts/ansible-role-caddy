.PHONY: setup deps requirements lint test test-arm test-caddyfile test-cloudflare test-debian

-include .env
export

GALAXY_FLAGS ?=

setup:
	@command -v uv >/dev/null || \
		(echo "uv is not installed" && exit 1)
	uv sync

deps: setup
	uv run ansible-galaxy collection install -r molecule/requirements.yml $(GALAXY_FLAGS)

lint: setup
	uv run ansible-lint .

test: setup deps
	uv run molecule test

test-arm: setup deps
	uv run molecule test -s ubuntu22_arm

test-caddyfile: setup deps
	uv run molecule test -s caddyfile

test-cloudflare: setup deps
	uv run molecule test -s cloudflare

test-debian: setup deps
	uv run molecule test -s debian
