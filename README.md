Caddy
=========

An Ansible role to install, configure and manage [Caddy](https://caddyserver.com/).

Defaults to installing from the official apt repository,
with optional support for downloading a custom binary with plugins.

Requirements
------------

- Debian/Ubuntu are supported by the apt install path.
- Systemd is required for service management.

Install
-------

This role is currently installed directly from GitHub. Add it to your
`requirements.yml` and install with `ansible-galaxy`:

```yaml
- name: paultibbetts.caddy
  src: https://github.com/paultibbetts/ansible-role-caddy
  version: 1.0.0
```

```sh
ansible-galaxy role install -r requirements.yml
```

Role Variables
--------------

Available variables, including defaults, are listed below:

This role supports two install methods: `apt` and `download`.

It defaults to using the `apt` package manager with the official Caddy repo.

Caddy can then be updated along with other packages using `apt`.

`download` is used for getting a custom binary, which can include plugins.

```yaml
caddy_install_method: apt
```

You can manage the state of Caddy, as well as purge the config and log directories if you
wanted to completely uninstall.

```yaml
caddy_state: present | absent
caddy_purge: false
```

You can control the service that runs Caddy with the following:

```yaml
caddy_manage_service: true
caddy_service_state: started
caddy_service_enabled: true
```
When service management is enabled (`caddy_manage_service: true`), the role
only attempts to start/reload Caddy for `apt` installs or when a
`caddy_caddyfile_template` is provided (since the service needs a config).

The config options for Caddy can be controlled with:

```yaml
caddy_log_path: /var/log/caddy # useful if your Caddyfile logs to files
caddy_config_path: /etc/caddy
```

You can pass in a template to be written to `caddy_config_path/Caddyfile` using:

```yaml
caddy_caddyfile_template: "" | "{{ playbook_dir }}/templates/Caddyfile.j2"
```

To pass in env values to Caddy from Ansible you must enable managing
the env file and then pass in the values.
These values may come from ansible-vault.

```yaml
caddy_manage_systemd_env_file: false
caddy_systemd_env_file_path: /etc/caddy/caddy.env
caddy_systemd_env: {} # key/value env vars written to the env file when managed
```

The following values are only applicable when installing via download.

```yaml
caddy_install_method: download
```

When using the download install method you are responsible for updating the
Caddy binary.

This can be done by building a pinned version of the binary with the
plugins you want included, hosting it, and passing the URL to `caddy_download_url`.

```yaml
caddy_download_url: "" # full URL to a binary
```

If you leave `caddy_download_url` empty and let the role generate the URL
for you then you will download the latest version of the binary.

If you are not using `caddy_download_url` and want to install plugins you
can pass them in using `caddy_plugins`.

`caddy_plugins` can be found on the [Caddy download page](https://caddyserver.com/download).
Plugins are expected to be listed using the go package name, such as:

```yaml
caddy_plugins:
  - github.com/caddy-dns/cloudflare
```

Download options:

```yaml
caddy_download_base_url: https://caddyserver.com/api/download
caddy_download_os: linux
caddy_download_arch: ansible_facts["architecture"]
caddy_plugins: [] # list/dict/string of plugin module paths
caddy_download_checksum: "" # optional sha256:<hex> checksum for the binary
caddy_download_force: false
caddy_download_tmp_path: /tmp/caddy
caddy_cleanup_download: true
```

The role will not check versions or install updates when using the
download method.

You can use `caddy_download_force` to force a new download. This
could be because you want to update to the latest version, have
changed the `caddy_download_url` or have included new plugins to
be installed.

Download-only service unit overrides:

```yaml
caddy_bin_path: /usr/bin/caddy
caddy_service_name: caddy
caddy_user_name: caddy
caddy_group_name: caddy
caddy_user_home_directory: /var/lib/caddy
caddy_systemd_unit_template: caddy.service.j2
caddy_ambient_capabilities: [CAP_NET_BIND_SERVICE]
```

You can pass in plain-text environment variables to Caddy with:

```yaml
caddy_env_vars: []
```

These are world-readable, so for secrets use the `caddy_systemd_env`
variable instead, which is written to a root-only file.

Example Playbook
----------------

Basic apt install:

```yaml
- hosts: servers
  become: true
  roles:
    - role: paultibbetts.caddy
```

Download a custom build with plugins:

```yaml
- hosts: servers
  become: true
  roles:
    - role: paultibbetts.caddy
      vars:
        caddy_install_method: download
        caddy_plugins:
          - github.com/caddy-dns/cloudflare
```

Download a specific prebuilt binary via URL (pinned release or custom build):

```yaml
- hosts: servers
  become: true
  roles:
    - role: paultibbetts.caddy
      vars:
        caddy_install_method: download
        caddy_download_url: "https://example.com/path/to/caddy"
        caddy_download_checksum: "sha256:0123456789abcdef..."
```

Use a Caddyfile template:

```yaml
- hosts: servers
  become: true
  roles:
    - role: paultibbetts.caddy
      vars:
        caddy_caddyfile_template: "{{ playbook_dir }}/templates/Caddyfile.j2"
```

Pass secrets to Caddy and set non-secret env vars:

```yaml
- hosts: servers
  become: true
  roles:
    - role: paultibbetts.caddy
      vars:
        caddy_caddyfile_template: "{{ playbook_dir }}/templates/Caddyfile.j2"
        caddy_install_method: download
        caddy_env_vars:
          - "CADDY_ENV_VAR=plaintext"
        caddy_manage_systemd_env_file: true
        caddy_systemd_env:
          CADDY_SECRET: "{{ vault_secret }}"
```

Caddy can be used in a private environment, like a homelab,
where the Cloudflare plugin is used to perform [DNS-01 challenges](https://letsencrypt.org/docs/challenge-types/#dns-01-challenge)
for Lets Encrypt to provide TLS certificates for domains it isn't able to reach directly.

```yaml
- hosts: homelab
  become: true
  roles:
    - role: paultibbetts.caddy
      vars:
        caddy_caddyfile_template: "{{ playbook_dir }}/templates/Caddyfile.j2"
        caddy_install_method: download
        caddy_plugins:
          - github.com/caddy-dns/cloudflare
        caddy_manage_systemd_env_file: true
        caddy_systemd_env:
            CF_API_TOKEN: "{{ vault_cf_api_token }}"
```

where the `Caddyfile.j2` template looks like:

```j2
service.example.com {
  tls {
    dns cloudflare {env.CF_API_TOKEN}
  }
  root * /srv/www/example.com/current
  file_server
}
```

Molecule Scenarios
------------------

- `default`: apt install only
- `cloudflare`: download build with Cloudflare DNS plugin
- `caddyfile`: apt install + Caddyfile end-to-end check
- `debian`: apt install on Debian 11/12 (bullseye/bookworm)
- `ubuntu22_arm`: ARM64 Ubuntu 22 + download build + Cloudflare plugin + Caddyfile

Requirements:

- Docker running locally (Molecule uses the Docker driver).
- Python installed (see `.python-version` file).
- Dependencies installed:
  - `pip install -r requirements-dev.txt`
- Collections installed:
  - `ansible-galaxy collection install -r molecule/requirements.yml`

Run a scenario:

```
molecule test -s default
molecule test -s cloudflare
molecule test -s caddyfile
molecule test -s debian
molecule test -s ubuntu22_arm
```

Using `uv`:

```
uv sync
uv run molecule test -s default
uv run molecule test -s cloudflare
uv run molecule test -s caddyfile
uv run molecule test -s debian
uv run molecule test -s ubuntu22_arm
```

A Makefile is included with recipes for common steps when working on 
this role. These include:

```sh
make lint
make test
make test-debian
```

If you use Colima on macOS, you need to prefix all molecule commands with:

```
DOCKER_HOST=unix://$HOME/.colima/default/docker.sock
```

Make will first check a `.env` file, so you can add this setting to that
file, using either the full path or a format that works with make:

```sh
# .env
DOCKER_HOST=unix://$(HOME)/.colima/default/docker.sock
```

License
-------

MIT

Author Information
------------------

Paul Tibbetts
