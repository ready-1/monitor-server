# Networking Reference

This guide covers how the Monitor Server project manages the transition from DHCP to a static address using Netplan and how connectivity is validated.

---

## Netplan Template

The Netplan template lives at `roles/network/templates/01-netcfg.yaml.j2`. It uses variables defined in `group_vars/all.yml`:

- `target_static_ip`
- `target_static_prefix`
- `target_gateway`
- `dns_servers`
- `primary_interface` (derived automatically from facts)

Example rendered file:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      addresses:
        - 10.211.55.99/24
      gateway4: 10.211.55.1
      nameservers:
        addresses:
          - 1.1.1.1
          - 8.8.8.8
```

After the template is written, the `network` role notifies the “Apply netplan config” handler, which runs `netplan apply`.

---

## Connection Transition Workflow

1. **Bootstrap Play Pre-tasks**
   - `dhcp_ip` is loaded from `group_vars/all.yml`.
   - `ansible_host` is set to the DHCP address so initial fact gathering succeeds.

2. **Network Role**
   - Confirms current IP matches the expected DHCP value.
   - Installs Netplan, renders the template, and applies it.
   - Updates `ansible_host`/`ansible_ssh_host` facts to the static IP.
   - Calls `meta: reset_connection` to force Ansible to reconnect.
   - Waits for SSH availability on the new address.
   - Collects fresh facts to confirm the static IP is in place.

3. **Bootstrap Post-tasks**
   - Resets the SSH connection once more.
  - Uses the control node to run an `ssh` command directly against the static IP (verifies credentials and network reachability).

---

## Validation Tasks

`roles/network/tasks/validate.yml` performs the following checks:

- `netplan generate` to confirm the configuration is syntactically valid.
- Re-run `netplan apply` and check status output.
- `ip -br a` to verify the static IP is assigned.
- `ip -4 route get 8.8.8.8` to ensure routing is correct.
- `.ping` to a public IP (ignored in check mode).
- `curl` probes to confirm network connectivity where applicable.

The bootstrap role (`roles/bootstrap/tasks/main.yml`) also runs:
- `netplan info`
- `ip -br a`
- `ip route get`
- Optional `ping`
- Once verified, it removes the legacy `ifupdown` package.

---

## Rollback Safety

If the `netplan apply` step fails and the IP does not change:

- The `network` role attempts to restore the previous configuration from the backup (`/etc/netplan/01-netcfg.yaml.backup`).
- The handler re-applies the original file and stops execution with a descriptive error.

---

## Variables Summary

| Variable | Location | Description |
| --- | --- | --- |
| `dhcp_ip` | `group_vars/all.yml` | Initial DHCP address used during bootstrap. |
| `target_static_ip` | `group_vars/all.yml` | Desired static IP address. |
| `target_static_prefix` | `group_vars/all.yml` | CIDR prefix length (e.g., `24`). |
| `target_gateway` | `group_vars/all.yml` | Default gateway for the static config. |
| `dns_servers` | `group_vars/all.yml` | List of DNS resolvers. |
| `primary_interface` | Derived | Interface name detected from facts (`ansible_default_ipv4.interface`). |

---

## Manual Checks

After the playbooks finish, consider running:

```bash
# On the control node
ssh monitor@<static-ip> hostname
ssh monitor@<static-ip> ip -br a

# On the target node (via SSH session)
netplan info
ip -br addr show
ip -4 route get 8.8.8.8
ping -c 1 8.8.8.8
```

---

## Troubleshooting

- **SSH fails after IP change**: Confirm the public key was deployed, check firewall rules, and verify static IP settings.
- **Netplan apply errors**: Run `sudo netplan --debug apply` on the target node for detailed output.
- **DNS resolution issues**: Confirm that `nameservers` are reachable and that the network role wrote the correct configuration.

For more tips, see `docs/TROUBLESHOOTING.md`.
