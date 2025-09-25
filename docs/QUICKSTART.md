# Monitor Server Quickstart

Use this guide for a rapid end-to-end provisioning run of the Monitor Server (NetAuto) stack on a fresh Debian 12 host.

---

## 1. Prerequisites

- **Control node**
  - Ansible 2.15+ (tested with Ansible 2.17)
  - Python 3.9+ (for Ansible)
  - SSH client and access to the target network
- **Target node**
  - Debian 12 (Bookworm)
  - Temporary DHCP address reachable from the control node
  - Ability to reboot and change to a static IP
- **Credentials**
  - Vault password (stored locally in `.vault_password`)
  - SSH key pair `~/.ssh/id_monitor_ed25519` on the control node

---

## 2. Prepare the Control Node

```bash
# Clone or pull the project repository (example)
git clone git@github.com:ready-1/monitor-server.git
cd monitor-server

# Install required Ansible collections
ansible-galaxy collection install -r requirements.yml
```

---

## 3. Configure Variables

Edit the variables under `group_vars` to match your environment:

```yaml
# group_vars/all.yml
dhcp_ip: "10.211.55.10"      # Temporary DHCP address of the host
target_static_ip: "10.211.55.99"
target_static_prefix: 24
target_gateway: "10.211.55.1"
dns_servers:
  - 1.1.1.1
  - 8.8.8.8
ssh_port: 22
ssh_allow_users: "monitor"
cockpit_version: "337-1~bpo12+1"
```

Sensitive values (e.g., sudo/become credentials, Nginx secrets) belong in `group_vars/all/become_vars.yml`, which is encrypted with Ansible Vault. Refer to `VAULT_USAGE.md` for editing instructions.

---

## 4. Set Up Vault Password and SSH Keys

```bash
# Create vault password file (never commit this file)
echo "your_vault_password" > .vault_password
chmod 600 .vault_password

# Ensure the monitor key pair exists
ls ~/.ssh/id_monitor_ed25519 ~/.ssh/id_monitor_ed25519.pub
```

The public key is automatically deployed to the target host during the bootstrap role.

---

## 5. Bootstrap the Host (DHCP → Static IP)

```bash
ansible-playbook -i bootstrap_inventory.ini bootstrap.yml
```

This playbook:
- Creates the `monitor` user
- Deploys the SSH public key
- Applies the Netplan configuration and switches to the static IP
- Removes legacy `ifupdown` packages after validating Netplan
- Ensures `systemd-timesyncd` is installed and synchronized

When the playbook finishes, the host is reachable over the static IP specified in `group_vars`.

---

## 6. Run the Main Provisioning Playbook

```bash
ansible-playbook -i inventory.ini site.yml
```

Roles executed in order:

1. `basic-utilities`
2. `ssh-hardening`
3. `cockpit`
4. `nginx-proxy`

Key outcomes:
- Essential packages installed and validated
- SSH hardened and UFW configured (ports 22/80/443/9090 open)
- Cockpit web console running on `https://<static-ip>:9090`
- Nginx reverse proxy installed from the official repo with self-signed TLS

---

## 7. Check Mode and Validation Tags (Optional)

Dry run:

```bash
ansible-playbook -i inventory.ini site.yml --check
```

Validation only:

```bash
ansible-playbook -i inventory.ini site.yml --tags validate
```

Cockpit role test harness:

```bash
ansible-playbook -i inventory.ini test_cockpit.yml
```

---

## 8. Next Steps

- Review `docs/NETWORKING.md` if the static-IP swap needs adjustment.
- Consult `docs/SECURITY.md` before exposing the host to untrusted networks.
- Use `docs/TROUBLESHOOTING.md` if any validation steps fail.

For a deeper architectural overview, start with `README.md`.
