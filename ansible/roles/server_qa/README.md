# Server QA Role

**Purpose**: Validates Stage 1 network setup effectiveness before proceeding with Stage 2 Docker provisioning.

## Overview

This role serves as the critical go/no-go validation point between Stage 1 and Stage 2. It ensures that:

- Stage 1 `setup_network.sh` script was executed successfully
- All network configuration is functional and persistent
- Server is ready for production Docker deployment
- No Stage 1 issues will cause Stage 2 failures

## Validation Criteria

### Stage 1 Script Verification
- [ ] `/etc/network/interfaces.d/` directory exists (netplan configuration)
- [ ] `/etc/ssh/sshd_config.d/99-monitor.conf` exists (SSH hardening)
- [ ] `/etc/netplan/01-network-setup.yaml` exists (static IP config)
- [ ] `/home/monitor/.ssh/authorized_keys` exists (SSH key authentication)

### Package Installation Check
- [ ] `netplan.io` installed
- [ ] `openssh-server` installed
- [ ] `network-manager` installed
- [ ] `systemd-networkd` installed

### System Services Status
- [ ] `systemd-networkd` service running
- [ ] `ssh` service running
- [ ] SSH configuration syntax valid

### Network Functionality
- [ ] Ping default gateway (local connectivity)
- [ ] Ping 8.8.8.8 (internet connectivity)
- [ ] DNS resolution working (`nslookup google.com`)
- [ ] Static IP properly configured and active
- [ ] Netplan configuration validates without errors

### SSH Accessibility
- [ ] SSH connection from control host successful
- [ ] Key-based authentication working

## Usage

```yaml
- hosts: flypack_servers
  roles:
    - server_qa
```

## Failure Behavior

If validation fails, the role will:

1. Provide detailed diagnostic output identifying the issue(s)
2. Halt the playbook execution with clear remediation steps
3. Prevent Stage 2 progression until Stage 1 issues are resolved

## Success Indicators

When validation passes, you'll see:

```
===================================================================================
Stage 2 READY: Server QA Validation PASSED
===================================================================================
✓ Stage 1 packages installed
✓ System services running
✓ SSH configuration valid
✓ Network connectivity confirmed
✓ DNS resolution working
✓ Static IP configuration active
✓ Netplan configuration persistent

Server is ready for Docker host provisioning.
Proceeding with Stage 2 Ansible roles.
===================================================================================
```

## Testing Notes

This role uses extensive diagnostic output and rescue blocks to provide actionable feedback. Run with `--verbose` (`-v`) for detailed task results during development.

## Variables

None required. All validation uses Ansible facts and direct system inspection.
