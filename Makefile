setup:
	uv sync

test: setup 
	DOCKER_HOST="unix://$(HOME)/.colima/default/docker.sock" uv run molecule test

test-pi: setup 
	DOCKER_HOST="unix://$(HOME)/.colima/default/docker.sock" uv run molecule test -s rpi_ubuntu22
