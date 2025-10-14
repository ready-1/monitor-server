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
ssh_allow_users: 'monitor'
cockpit_version: '337-1~bpo12+1'
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

The public key is automatically configured during network setup.

---

## 5. Deployment Workflow (Recommended)

For fresh VM deployments, use this streamlined workflow:

### Step 1: Clear SSH Keychain
```bash
# Clear all loaded SSH keys to avoid authentication conflicts
ssh-add -D
```

### Step 2: Transfer Setup Script
```bash
# Copy the network setup script to the fresh VM (replace <dhcp-ip> with actual IP)
scp ./setup_network.sh monitor@<dhcp-ip>:/home/monitor/
```

### Step 3: Configure VM Network & SSH
```bash
# SSH to the VM using password authentication
ssh monitor@<dhcp-ip>

# Make script executable and run network setup
sudo chmod +x /home/monitor/setup_network.sh
sudo /home/monitor/setup_network.sh
```

The script will:
- Install all required network dependencies
- Configure static IP (10.211.55.99)
- Set up SSH keys and harden the configuration
- Configure firewall and NTP

### Step 4: Reconnect with Key Authentication
```bash
# Exit SSH session and restore your keychain
exit
eval "$(ssh-agent -s)" && ssh-add ~/.ssh/id_monitor_ed25519

# Connect to the configured static IP
ssh monitor@10.211.55.99
```

### Step 5: Deploy Monitor Stack
```bash
# Test Ansible connectivity
ansible -i inventory.ini all -m ping

# Run full deployment
ansible-playbook -i inventory.ini site.yml
```

---

## 6. Legacy Bootstrap Method (Deprecated)

**Note**: The old bootstrap method with `bootstrap.yml` is deprecated but still available for reference:

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

## 7. Run the Main Provisioning Playbook

```bash
ansible-playbook -i inventory.ini site.yml
```

Roles executed in order:

1. `basic-utilities`
2. `ssh-hardening`
3. `cockpit`
4. `nginx-proxy`
5. `website`

Key outcomes:
- Essential packages installed and validated
- SSH hardened and UFW configured (ports 22/80/443/9090 open)
- Cockpit web console running on `https://10.211.55.99:9090`
- Nginx reverse proxy installed from the official repo with self-signed TLS
- Custom website with Bootstrap 5, responsive design, and dark mode toggle

---

## 8. Check Mode and Validation Tags (Optional)

Dry run:

```bash
ansible-playbook -i inventory.ini site.yml --check
```

Validation only:

```bash
ansible-playbook -i inventory.ini site.yml --tags validate
```

Test Cockpit functionality:

```bash
ansible-playbook -i inventory.ini test_cockpit.yml
```

---

## 9. Next Steps

- **Access your server**: https://10.211.55.99
- **Cockpit console**: https://10.211.55.99:9090
- Review `docs/NETWORKING.md` if the static-IP swap needs adjustment.
- Consult `docs/SECURITY.md` before exposing the host to untrusted networks.
- Use `docs/TROUBLESHOOTING.md` if any validation steps fail.
