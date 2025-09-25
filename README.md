# Monitor Server Provisioning (NetAuto)

An Ansible automation stack for building a hardened Debian 12 “Monitor Server” with a Cockpit web console and Nginx reverse proxy. The project delivers a repeatable bootstrap process, opinionated security defaults, and validation tooling to verify every step.

---

## Highlights

- Bootstrap workflow that migrates a host from DHCP to a static IP using Netplan.
- Hardened `monitor` SSH user with key-based access and UFW enforcement.
- Nginx reverse proxy installed from the official nginx.org repository with self-signed TLS (ready for trusted certificates).
- Cockpit web console sourced from Debian backports with automated idempotency tests.
- Validation tasks (`--tags validate`) across all roles plus a dedicated Cockpit test harness.
- Secrets managed through Ansible Vault with documented usage.
- Modular roles and documentation for quick onboarding.

---

## Architecture at a Glance

```
bootstrap.yml
 ├─ role: initial_setup   # create user + SSH key
 ├─ role: network         # render/apply Netplan, switch to static IP
 └─ role: bootstrap       # netplan validation, remove ifupdown, NTP sync

site.yml
 ├─ role: basic-utilities # baseline packages
 ├─ role: ssh-hardening   # sshd_config + UFW
 ├─ role: cockpit         # install cockpit + open port 9090
 └─ role: nginx-proxy     # official nginx repo, TLS scaffold, reverse proxy
```

Each role ships with a `validate` tag for quick health checks. The `test_cockpit.yml` playbook exercises idempotency and error recovery.

---

## Requirements

| Component | Version / Notes |
| --- | --- |
| Control node | Ansible 2.15+ (tested on 2.17), Python 3.9+, SSH client |
| Target node | Debian 12 (Bookworm) with temporary DHCP connectivity |
| Collections | Install via `ansible-galaxy collection install -r requirements.yml` (community.crypto, community.general) |
| Credentials | Vault password (`.vault_password`) and SSH key `~/.ssh/id_monitor_ed25519` on the control node |

---

## Getting Started

Follow the step-by-step instructions in **[`docs/QUICKSTART.md`](docs/QUICKSTART.md)**. Summary:

1. Clone the repository and install required collections.
2. Update `group_vars/all.yml` (network, SSH, Cockpit/Nginx variables) and encrypted secrets in `group_vars/all/become_vars.yml`.
3. Create `.vault_password` (never commit it).
4. Run `ansible-playbook -i bootstrap_inventory.ini bootstrap.yml` to migrate from DHCP to static IP.
5. Run `ansible-playbook -i inventory.ini site.yml` to configure the full stack.
6. Optional: `--check`, `--tags validate`, or `ansible-playbook -i inventory.ini test_cockpit.yml`.

---

## Documentation Set

| Topic | Description |
| --- | --- |
| [`docs/QUICKSTART.md`](docs/QUICKSTART.md) | End-to-end provisioning walkthrough |
| [`docs/INVENTORY.md`](docs/INVENTORY.md) | How bootstrap vs. main inventories work |
| [`docs/NETWORKING.md`](docs/NETWORKING.md) | Netplan templating, connection resets, rollback logic |
| [`docs/ROLES.md`](docs/ROLES.md) | Responsibilities and validations per role |
| [`docs/SECURITY.md`](docs/SECURITY.md) | Hardening measures and production recommendations |
| [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) | Common failure modes and fixes |
| [`VAULT_USAGE.md`](VAULT_USAGE.md) | Vault workflow and best practices |

---

## Inventories & Variables

- **Bootstrap** (`bootstrap_inventory.ini`): no `ansible_host`; password-based SSH using vaulted `vault_become_password`. `bootstrap.yml` injects `ansible_host` from `dhcp_ip`.
- **Main** (`inventory.ini`): targets the static IP with key-based SSH and vaulted sudo password.

Key variables live in `group_vars/all.yml`. Highlights:

| Variable | Purpose |
| --- | --- |
| `dhcp_ip` | Temporary address used during bootstrap |
| `target_static_ip`, `target_static_prefix`, `target_gateway`, `dns_servers` | Netplan configuration |
| `ssh_port`, `ssh_allow_users` | SSH hardening |
| `cockpit_version`, `nginx_version` | Package pinning |
| `nginx_ssl_cert_path`, `nginx_ssl_key_path` | Self-signed TLS file paths |
| `vault_become_password` | Encrypted sudo password (stored in `group_vars/all/become_vars.yml`) |

---

## Validation & Testing

- Run `ansible-playbook -i inventory.ini site.yml --tags validate` to execute role-specific checks (service status, port reachability, certificate existence, etc.).
- `ansible-playbook -i inventory.ini test_cockpit.yml` validates idempotency and error recovery for the Cockpit role.
- Pre-tasks in both `bootstrap.yml` and `site.yml` assert privilege escalation with Vault before proceeding.

---

## Security Overview

- Hardened `sshd_config` disables root login and enforces key-based authentication.
- UFW defaults: deny incoming, allow outgoing; opens ports 22/80/443/9090.
- Self-signed certificates generated for Cockpit and Nginx (swap with trusted certs for production).
- `.vault_password` referenced by `ansible.cfg`; see `VAULT_USAGE.md` for secure handling.
- Suggestions for further hardening (Fail2ban, unattended upgrades, etc.) outlined in `docs/SECURITY.md`.

---

## Troubleshooting

Consult **[`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md)** for symptom-driven fixes covering vault issues, SSH connectivity, Netplan, Nginx, Cockpit, collection dependencies, and sudo failures. A few quick commands:

```bash
ansible -i inventory.ini all -m ping
ansible-playbook -i inventory.ini site.yml -vv
ansible-playbook -i inventory.ini site.yml --start-at-task "<task name>"
```

---

## Repository Layout (Key Files)

```
ansible.cfg                # Project defaults (become enabled, YAML output, vault file)
bootstrap.yml              # DHCP → static bootstrap play
site.yml                   # Main configuration playbook
test_cockpit.yml           # Cockpit validation harness
inventory.ini              # Static-IP inventory
bootstrap_inventory.ini    # Bootstrap inventory (DHCP)
group_vars/
  all.yml                  # Global non-sensitive vars
  all/                     # Scoped variable files (nginx, ssh_hardening, become vars, etc.)
roles/
  basic-utilities/         # Package baseline + validation
  ssh-hardening/           # sshd_config template & UFW
  cockpit/                 # Cockpit installation, validation, defaults
  nginx-proxy/             # Nginx repo, TLS scaffolding, validation
  network/                 # Netplan template, IP transition
  bootstrap/               # Post-network cleanup (ifupdown removal, NTP)
docs/                      # Supplemental documentation (Quickstart, Networking, Security, etc.)
requirements.yml           # Collection dependencies
VAULT_USAGE.md             # Vault workflow
```

---

## Future Enhancements

- Consolidate `group_vars/all.yml` and `group_vars/all/` into a single hierarchy (`group_vars/all/main.yml`).
- Introduce automated certificate management (e.g., Let’s Encrypt).
- Add host monitoring/metrics roles (Prometheus node exporter, etc.).
- Extend validation suites for Nginx proxy scenarios (e.g., upstream health checks).

Contributions and refinements are welcome—open an issue or pull request to discuss changes.
