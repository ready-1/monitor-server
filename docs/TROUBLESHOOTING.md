# Troubleshooting Guide

Use this reference to diagnose common issues encountered while provisioning or operating the Monitor Server.

---

## Vault and Credentials

| Symptom | Check | Resolution |
| --- | --- | --- |
| `ERROR! Attempting to decrypt but no vault secrets found` | Ensure `.vault_password` exists and has correct permissions. | Create it (`echo "password" > .vault_password && chmod 600 .vault_password`). If you prefer prompts, remove the file and run with `--ask-vault-pass`. |
| `ERROR! Decryption failed` | Vault password mismatch or corrupted file. | Confirm the password, re-encrypt the file with the right password (`ansible-vault rekey group_vars/all/become_vars.yml`). |
| SSH authentication fails after bootstrap | Verify `~/.ssh/id_monitor_ed25519` exists and matches the key deployed to the host. | Regenerate or copy the key pair, then re-run `bootstrap.yml`. |

Refer to `VAULT_USAGE.md` for editing vaulted files safely.

---

## SSH and Connectivity

| Symptom | Check | Resolution |
| --- | --- | --- |
| `UNREACHABLE!` or `Failed to connect to the host via ssh` | Confirm the host IP (DHCP vs static) and firewall status. | Run `ansible -i <inventory> all -m ping`. Ensure UFW allows SSH and that `dhcp_ip`/`target_static_ip` values are correct. |
| SSH prompts for password after main playbook | `ansible_user`, `ansible_ssh_private_key_file`, or authorized keys not aligned. | Confirm the `monitor` user’s `authorized_keys` contains the correct public key. |
| Connection drops during IP transition | Netplan misconfiguration. | Check `/etc/netplan/01-netcfg.yaml`. Use the backup file if needed and re-run `netplan apply`. |

---

## Netplan / Networking

| Symptom | Check | Resolution |
| --- | --- | --- |
| Static IP not applied | Output of `ip -br a` differs from `target_static_ip`. | Run `sudo netplan --debug apply`, inspect `/etc/netplan/01-netcfg.yaml`. |
| `netplan apply` fails in playbook | Error logs from handler. | SSH to the host (if reachable) and run `sudo netplan apply` manually to see full error. Ensure interface name and subnet mask are correct. |
| Cannot resolve DNS | `/etc/systemd/resolved.conf` or netplan `nameservers` incorrect. | Confirm `dns_servers` in `group_vars/all.yml`. Restart systemd-resolved (`sudo systemctl restart systemd-resolved`). |

---

## Cockpit

| Symptom | Check | Resolution |
| --- | --- | --- |
| Cockpit not accessible | Service status `systemctl status cockpit.socket`. | Ensure port 9090 is open (`ufw status`). Restart socket (`sudo systemctl restart cockpit.socket`). |
| Browser warns about certificate | Expected: self-signed cert. | Replace with trusted certs following `docs/SECURITY.md`. |
| Test playbook fails idempotency | Review `test_cockpit.yml` tasks. | Fix underlying role changes, then re-run validation. |

---

## Nginx Proxy

| Symptom | Check | Resolution |
| --- | --- | --- |
| Nginx service not running | `systemctl status nginx`. | Review `/var/log/nginx/error.log`. Ensure repository key installed and configuration syntax valid (`nginx -t`). Re-run role with `--tags nginx`. |
| Unable to access HTTPS | Self-signed cert not generated. | Verify files exist at paths specified in `group_vars/all/nginx.yml`. Re-run role (which regenerates certificates if missing). |
| UFW blocks HTTP/HTTPS | `ufw status`. | Ensure the role executed successfully; re-run `ansible-playbook -i inventory.ini site.yml --tags nginx-proxy`. |

---

## Ansible Collections

| Symptom | Check | Resolution |
| --- | --- | --- |
| `ERROR! couldn't resolve module/action 'community.crypto.openssl_privatekey'` | Required collections missing. | Install via `ansible-galaxy collection install -r requirements.yml`. |
| Version conflicts | `ansible-galaxy collection list`. | Pin to specific versions in `requirements.yml` if necessary. |

---

## Permissions and sudo

| Symptom | Check | Resolution |
| --- | --- | --- |
| `sudo: a password is required` | Vaulted password not provided. | Confirm `.vault_password` or use `--ask-become-pass`. |
| Privilege escalation validation fails | Pre-task assertions in playbooks. | Ensure the `monitor` user is in sudoers and the vault password matches the user’s sudo password. |

---

## General Playbook Issues

- Run with increased verbosity:

  ```bash
  ansible-playbook -i inventory.ini site.yml -vvv
  ```

- Limit to a specific host or role to isolate issues:

  ```bash
  ansible-playbook -i inventory.ini site.yml --limit monitor-server --tags validate
  ```

- Check Ansible configuration in `ansible.cfg` for defaults that might need adjustment in your environment (e.g., `host_key_checking = False`).

---

## Getting Help

- Review role-specific docs:
  - `docs/ROLES.md`
  - `docs/NETWORKING.md`
  - `docs/SECURITY.md`
- Review upstream references:
  - [Netplan Reference](https://netplan.io/reference)
  - [Ansible Playbook Best Practices](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_best_practices.html)
- Use Git history or `ansible-playbook --start-at-task "<task name>"` to resume after failures.

Keep notes of environment-specific quirks and consider adding them to this guide for future maintainers.
