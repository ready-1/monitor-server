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
