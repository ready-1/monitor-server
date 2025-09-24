# NetAuto Server Ansible Playbook

This project provisions a Debian VM as a monitoring server (Phase 1) and enables switch management capabilities (Phase 2). It is designed to be run from a Mac control node.

## Project Overview

- **Phase 1**: Set up a Debian VM as a monitoring server
- **Phase 2**: Enable switch management capabilities
- **Control Node**: Mac OS X

## Setup Instructions

### Prerequisites

1. Install Git (if not already installed):
   ```
   brew install git
   ```

2. Install Ansible (if not already installed):
   ```
   brew install ansible
   ```

### Getting Started

1. Clone the repository:
   ```
   git clone git@github.com:ready-1/monitor-server.git
   cd monitor-server
   ```

2. Verify Ansible installation:
   ```
   ansible --version
   ```

3. Set up SSH key authentication:
   - Ensure you have an SSH key pair. If not, create one:
     ```
     ssh-keygen -t ed25519 -C "your_email@example.com"
     ```
   - Copy your public key to the target host:
     ```
     ssh-copy-id -i ~/.ssh/id_ed25519.pub monitor@10.211.55.6
     ```

## Inventory Details

The `inventory.ini` file defines the hosts and groups for this project:

```ini
[monitors]
monitor-server ansible_host=10.211.55.6 ansible_user=monitor ansible_ssh_private_key_file=~/.ssh/id_monitor_ed25519
```

- `[monitors]`: Group name for monitoring servers
- `monitor-server`: Alias for the host
- `ansible_host`: IP address of the target host
- `ansible_user`: SSH user for connecting to the host
- `ansible_ssh_private_key_file`: Path to the SSH private key file

To modify for different environments, update the IP address and user details as needed.

## Basic Commands

1. Test connectivity to all hosts:
   ```
   ansible all -m ping -i inventory.ini
   ```

2. Run the playbook in dry-run mode:
   ```
   ansible-playbook -i inventory.ini site.yml --check -vv
   ```

3. Run the playbook for real:
   ```
   ansible-playbook -i inventory.ini site.yml -vv
   ```

4. Run with sudo password prompt:
   ```
   ansible-playbook -i inventory.ini site.yml -vv --ask-become-pass
   ```

Use `-vv` for verbose output to troubleshoot connectivity issues.

## Project Structure

- `ansible.cfg`: Ansible configuration file
- `inventory.ini`: Inventory file defining hosts and groups
- `site.yml`: Main playbook file
- `roles/`: Directory for organizing reusable roles (currently empty)

## Adding New Functionality

To add new functionality:
1. Create a new role: `ansible-galaxy init roles/new_role_name`
2. Add tasks to `roles/new_role_name/tasks/main.yml`
3. Include the role in `site.yml`

## Troubleshooting

- Ensure target hosts allow sudo access for the `monitor` user
- Check SSH key permissions (should be 600)
- Verify network connectivity between control node and target hosts

