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

1. Update the `inventory.ini` file with your target server details.
2. Review and adjust variables in `group_vars/all.yml` if needed.
3. Run the playbook:

   ```
   ansible-playbook -i inventory.ini site.yml
   ```

4. For a dry run (check mode):

   ```
   ansible-playbook -i inventory.ini site.yml --check
   ```

## Roles

- `basic-utilities`: Installs and validates essential packages
- `ssh-hardening`: Applies SSH security configurations
- `nginx-proxy`: Sets up Nginx as a reverse proxy
- `cockpit`: Installs and configures the Cockpit web console

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
