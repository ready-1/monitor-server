# NetAuto Server Provisioning

This Ansible playbook automates the provisioning of a NetAuto Server with Nginx proxy and Cockpit web console.

## Features

- Basic utilities installation and validation
- SSH hardening
- Nginx proxy setup
- Cockpit web console installation and configuration
- UFW firewall configuration

## Prerequisites

- Ansible 2.9 or higher
- Target Debian 12 system
- SSH access to the target system

## Usage

### Bootstrap Process

1. Update the `group_vars/all.yml` file with your DHCP IP:
   ```yaml
   dhcp_ip: "your_dhcp_ip_here"
   ```

2. Update the `inventory.ini` file with your target static IP:
   ```ini
   [servers]
   monitor-server ansible_host=your_static_ip_here ansible_user=monitor
   ```

3. Run the bootstrap playbook:
   ```
   ansible-playbook -i bootstrap_inventory.ini bootstrap.yml
   ```
   This will configure the server with the static IP and set up initial SSH access.

### Main Configuration

After the bootstrap process is complete:

1. Review and adjust variables in `group_vars/all.yml` if needed.
2. Run the main playbook:
   ```
   ansible-playbook -i inventory.ini site.yml
   ```

3. For a dry run (check mode):
   ```
   ansible-playbook -i inventory.ini site.yml --check
   ```

## Roles

The roles are executed in the following order:

1. `basic-utilities`: Installs and validates essential packages
2. `ssh-hardening`: Applies SSH security configurations
3. `cockpit`: Installs and configures the Cockpit web console
4. `nginx-proxy`: Sets up Nginx as a reverse proxy

## Nginx-Proxy Role
- Installs from official stable repo, pins to {{ nginx_version }}.
- Sets up basic HTTPS with self-signed cert.
- Prepares for future proxies (placeholders in default config), excludes Cockpit.
- Opens UFW 80/443.
- Validation: service status, curl checks.

## Configuration

- Nginx proxy listens on ports 80 (HTTP) and 443 (HTTPS)
- Cockpit web console is accessible on port 9090
- UFW firewall is configured to allow these ports

## Validation

The playbook includes various validation tasks to ensure:

- Correct installation of packages
- Proper configuration of services
- Accessibility of web interfaces

## Notes

- This playbook is designed for Debian 12 systems
- Always run in check mode first before applying changes
- Backup your system before running the playbook

For more detailed information, refer to the individual role READMEs in the `roles/` directory.

## Remove ifupdown (Branch: remove-ifupdown)

To prevent conflicts between legacy `ifupdown` networking scripts and Netplan-managed interfaces, the bootstrap play now validates Netplan and removes the `ifupdown` package immediately after Netplan has been applied by the `network` role.

### Directory structure evaluation
- Root layout (playbooks, inventories, ansible.cfg, README) aligns with Ansible best practices.
- Roles remain modular and scoped (`initial_setup`, `network`, `basic-utilities`, `ssh-hardening`, `cockpit`, `nginx-proxy`), and a dedicated `bootstrap` role now encapsulates post-network cleanup tasks.
- `group_vars/all.yml` and `group_vars/all/` coexist. This is supported but can be confusing; consider consolidating into `group_vars/all/` with a `main.yml` in a follow-up change.

### Validation steps added
- Confirm Netplan binary exists and gather `netplan info`.
- Capture interface status via `ip -br a`.
- Check routing (and optionally ICMP connectivity) to verify networking is operational before removal.
- Remove `ifupdown` with `apt` (Debian 12 stable repositories) only after validation, then notify a handler that reloads the active backend (`systemd-networkd` or `NetworkManager`) without forcing a restart.

### Suggested manual validation commands
- `ansible-playbook -i bootstrap_inventory.ini bootstrap.yml -vv`
- `ansible-playbook -i inventory.ini site.yml -vv`
- `netplan info`
- `ip -br a`
- `ip -4 route get 8.8.8.8`
- `ping -c 1 8.8.8.8`

### References
- Ansible Best Practices (Directory Layout): https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_best_practices.html#directory-layout
- Netplan Reference: https://netplan.io/reference
