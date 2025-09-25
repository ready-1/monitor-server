# Role Overview

This reference summarizes each Ansible role shipped with the Monitor Server project. Use it to understand responsibilities, dependencies, and validation strategies before modifying or extending the stack.

---

## initial_setup

**Purpose**: Create the `monitor` user with sudo privileges and install the controller’s SSH public key.

**Key tasks**:
- Create user, set shell, and add to `sudo` group.
- Create `~monitor/.ssh` with correct permissions.
- Deploy `id_monitor_ed25519.pub` from the control node.
- Trigger SSH restart handler after updating `sshd_config`.

**Validation** (`tasks/validate.yml`):
- Confirms the user exists and belongs to the sudo group.
- Verifies `.ssh` directory mode `0700` and `authorized_keys` presence.
- Ensures the expected key appears in `authorized_keys`.

---

## network

**Purpose**: Transition the host from a DHCP address to the target static IP using Netplan.

**Key tasks**:
- Capture current IP and confirm it matches `dhcp_ip`.
- Install `netplan.io` and render `01-netcfg.yaml`.
- Backup the existing Netplan config and apply the new one.
- Update runtime facts (`ansible_host`, `ansible_ssh_host`) to the static IP.
- Reset connections and wait for SSH to respond on the new address.
- Cleanup backup files when successful.

**Handlers**:
- `Apply netplan config`: runs `netplan apply`.

**Validation**:
- `netplan generate/apply` checks.
- IP and route verification via `ip -br a`, `ip route get`.
- Connectivity checks (`ping`, `curl`), where applicable.

**Rollback logic**:
- If IP validation fails, restores the backup configuration and reapplies it, then fails with an explanatory message.

---

## bootstrap

**Purpose**: Post-network hygiene and safety checks executed after the static IP is active.

**Key tasks**:
- Verify Netplan binary presence and network connectivity.
- Ensure `systemd-timesyncd` is installed and NTP synchronization is active.
- Refresh APT cache ignoring clock issues (if needed).
- Remove legacy `ifupdown` package once Netplan is verified.
- Notify handler to reload the network backend after package removal.

**Validation**:
- Assertions that Netplan is operational before `ifupdown` removal.
- NTP sync confirmation using `timedatectl`.
- Route and ping checks for sanity.

---

## basic-utilities

**Purpose**: Install foundational packages used by other roles and for manual troubleshooting.

**Key tasks**:
- Install packages: `curl`, `iputils-ping`, `net-tools`, `apt-transport-https`, `ca-certificates`.

**Validation**:
- Query `dpkg -l` for each package.
- Functional tests: `curl` HTTPS request and `ping` to external hosts.
- Debug summary indicating success.

---

## ssh-hardening

**Purpose**: Harden SSH configuration and enforce firewall policies.

**Key tasks**:
- Install and enable UFW.
- Deploy hardened `sshd_config` via template (`templates/sshd_config.j2`).
- Restart SSH service when configuration changes.
- Enable UFW and configure default policies.
- Allow SSH port (`ssh_port` variable, default 22).
- Reload UFW to ensure rules are active.

**Validation**:
- Runs additional checks in `roles/ssh-hardening/tasks/validate.yml` (service status, firewall rules).

---

## cockpit

**Purpose**: Install and configure Cockpit from Debian backports.

**Key tasks**:
- Add the `bookworm-backports` repository if not already present.
- Install the `cockpit` package pinned to `cockpit_version`.
- Enable and start `cockpit.socket`.
- Open port 9090 in UFW (skip in check mode).
- Include validation tasks and support for check mode.

**Validation**:
- Confirms service state, port accessibility, UFW rule presence, and certificate file existence.
- Uses `uri` module to verify the HTTPS endpoint.

**Handlers**:
- `restart cockpit`: restarts `cockpit.socket` when configuration changes.

**Test playbook**:
- `test_cockpit.yml` exercises idempotency and error recovery by intentionally stopping the service and re-running the role.

---

## nginx-proxy

**Purpose**: Install Nginx from the official nginx.org repository and configure it as a reverse proxy with self-signed TLS.

**Key tasks**:
- Install `gnupg`, add official repository key, and configure the APT source.
- Create preferences to pin Nginx to the repository version (`nginx_version`).
- Install Nginx and required Python packages (`python3-setuptools`, `python3-cryptography`).
- Generate self-signed certificates using `community.crypto` modules.
- Deploy `nginx.conf`, `default.conf`, and supporting directories.
- Ensure Nginx service is enabled, started, and restarted when configs change.
- Open ports 80 and 443 in UFW.

**Handlers**:
- `reload_nginx`
- `restart_nginx`

**Validation**:
- Tasks in `roles/nginx-proxy/tasks/validate.yml` (service status, TLS assets, port checks).

---

## Role Execution Order

- **Bootstrap Workflow** (`bootstrap.yml`):
  1. `initial_setup`
  2. `network`
  3. `bootstrap`

- **Primary Provisioning** (`site.yml`):
  1. `basic-utilities`
  2. `ssh-hardening`
  3. `cockpit`
  4. `nginx-proxy`

Each role is designed to be idempotent and includes validation tasks tagged with `validate` for targeted execution via `--tags validate`.
