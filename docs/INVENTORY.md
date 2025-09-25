# Inventory Guide

This document explains how the Monitor Server project uses inventories during the provisioning lifecycle.

---

## Files

| File | Purpose | Authentication |
| --- | --- | --- |
| `bootstrap_inventory.ini` | Used during the bootstrap phase while the host still uses its DHCP address. | Username/password (vault) |
| `inventory.ini` | Used after the host switches to its static IP for the main configuration. | SSH key + vaulted sudo password |

---

## Bootstrap Inventory (`bootstrap_inventory.ini`)

```ini
[servers]
monitor-server

[all:vars]
ansible_user=monitor
ansible_ssh_pass={{ vault_become_password }}
ansible_python_interpreter=/usr/bin/python3
ansible_become_method=sudo
ansible_become_pass={{ vault_become_password }}
```

Key points:

- No `ansible_host` is defined. Instead, the bootstrap play sets `ansible_host` dynamically to the DHCP address provided in `group_vars/all.yml` (`dhcp_ip`).
- Password-based SSH is used because the target host may not yet contain the control node’s public key.
- The same vaulted `vault_become_password` is reused for both SSH and privilege escalation during bootstrap.

---

## Main Inventory (`inventory.ini`)

```ini
[servers]
monitor-server ansible_host=10.211.55.99 ansible_user=monitor

[all:vars]
ansible_user=monitor
ansible_ssh_private_key_file=/Users/bob/.ssh/id_monitor_ed25519
ansible_python_interpreter=/usr/bin/python3
ansible_become_method=sudo
ansible_become_pass={{ vault_become_password }}
```

Key points:

- `ansible_host` now points to the static IP configured by the network role.
- SSH authentication happens via the deployed key (`ansible_ssh_private_key_file`).
- Privilege escalation continues to use the vaulted sudo password.

---

## Dynamic Host Updates Inside Playbooks

Both `bootstrap.yml` and `site.yml` modify connection facts to keep Ansible aligned with the active IP.

1. **Bootstrap Play**
   - Loads `dhcp_ip` and sets `ansible_host` before gathering facts.
   - After Netplan applies the static IP, post-tasks reset the SSH connection and confirm connectivity to the new address.

2. **Network Role (within `bootstrap.yml`)**
   - After writing the Netplan config, the role updates runtime facts:
     ```yaml
     - set_fact:
         ansible_host: "{{ target_static_ip }}"
         ansible_ssh_host: "{{ target_static_ip }}"
     - add_host:
         name: "{{ inventory_hostname }}"
         ansible_host: "{{ target_static_ip }}"
         ansible_ssh_host: "{{ target_static_ip }}"
         ansible_ssh_private_key_file: "{{ hostvars[inventory_hostname].ansible_ssh_private_key_file | default(ansible_ssh_private_key_file) }}"
         ansible_private_key_file: "{{ hostvars[inventory_hostname].ansible_ssh_private_key_file | default(ansible_ssh_private_key_file) }}"
         ansible_ssh_common_args: "-o IdentitiesOnly=yes -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
     - meta: reset_connection
     ```

3. **Post-bootstrap Tasks**
   - Wait for SSH on the new static address.
   - Run a manual `ssh` command from localhost to verify connectivity.
   - Reset the connection to ensure the remaining roles use the static IP.

---

## Managing Multiple Hosts

To extend the solution:

- Duplicate inventory groups (`[servers]`) for each host.
- Provide host-specific variables either inline (`ansible_host=<ip>`) or via `host_vars/<hostname>/`.
- Each host should have its own DHCP and static IP assignments defined in `group_vars` or `host_vars`.

Remember to ensure that each host’s vault-protected credentials are available and that their SSH keys align with the control node’s configuration.

---

## Tips

- Always run `ansible-playbook` with the matching inventory (`bootstrap_inventory.ini` for bootstrap, `inventory.ini` for the main play).
- Use `--limit <hostname>` when targeting a single server.
- In check mode (`--check`), connection resets still occur but skip actions that alter state.
- Keep inventories under version control and manage sensitive data exclusively through vault-encrypted files.
