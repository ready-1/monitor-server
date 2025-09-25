# Security Considerations

This document highlights the security posture of the Monitor Server stack and provides recommendations for hardening production deployments.

---

## SSH Hardening

- **Configuration**: `roles/ssh-hardening/templates/sshd_config.j2`
  - Enforces protocol 2.
  - Disables root login, password authentication (after bootstrap), X11 forwarding, and agent forwarding.
  - Limits authentication attempts via `MaxAuthTries` (set to 8 by default to tolerate multiple keys).
  - Restricts access to `ssh_allow_users` (default: `monitor`).
  - Enables key-based authentication, mandated once bootstrap completes.

- **Recommendations**:
  - Keep `ssh_allow_users` scoped to necessary accounts.
  - Rotate SSH keys periodically.
  - Consider enabling multi-factor authentication for sensitive environments.

---

## Firewall (UFW)

- Enabled by default with the following rules:
  - Allow SSH (`ssh_port`, default 22).
  - Allow HTTP (80) and HTTPS (443) for Nginx.
  - Allow Cockpit (9090).
  - Default policy: deny incoming, allow outgoing.

- **Recommendations**:
  - Review allowed ports before exposing the host publicly.
  - Add rate-limiting rules for SSH (e.g., `ufw limit ssh`).
  - Disable Cockpit or restrict access using firewall rules if not needed.

---

## TLS Certificates

- **Cockpit**: Uses the self-signed certificate located at `/etc/cockpit/ws-certs.d/0-self-signed.cert`.
- **Nginx**:
  - Generates a self-signed certificate using `community.crypto`.
  - Key path: `/etc/ssl/private/nginx-selfsigned.key`
  - Certificate path: `/etc/ssl/certs/nginx-selfsigned.crt`
  - Both are intended as placeholders.

- **Recommendations**:
  - Replace self-signed certificates with trusted ones (e.g., Let’s Encrypt).
  - Integrate certificate renewal workflows (Acme, Vault, etc.).
  - Configure Nginx to proxy Cockpit and other services with proper TLS termination and header sanitization.

---

## Ansible Vault

- Sensitive data resides in `group_vars/all/become_vars.yml` (encrypted).
- `ansible.cfg` uses `vault_password_file = .vault_password` by default.
- **Recommendations**:
  - Store `.vault_password` securely (never commit).
  - Rotate vault passwords and re-encrypt secrets periodically.
  - For shared teams, consider using a password manager or key management service to distribute vault credentials.

Refer to `VAULT_USAGE.md` for configuration and operational details.

---

## Privilege Escalation

- All playbooks run with `become: true` by default, elevating via `sudo`.
- Validation tasks confirm privilege escalation is functional before executing high-impact operations.

- **Recommendations**:
  - Limit sudo capabilities for the `monitor` user to required commands.
  - Audit `/etc/sudoers` and associated policy files regularly.

---

## Logging and Monitoring

- Cockpit provides a GUI for service management but does not replace centralized logging.
- **Recommendations**:
  - Forward logs to a SIEM or logging stack (e.g., ELK, Loki) for long-term retention.
  - Monitor authentication attempts via `/var/log/auth.log`.

---

## Host Hardening

- Ensure the base OS is up to date (`apt upgrade`).
- Consider installing additional security tooling:
  - Fail2ban for SSH protection.
  - unattended-upgrades for automatic security patches.
  - AIDE or OSSEC for integrity monitoring.

These additions can be built as new roles or integrated with existing ones.

---

## Future Enhancements

- Integrate Nginx with Cockpit to serve Cockpit behind TLS termination.
- Introduce automated certificate management.
- Add role-specific AppArmor or SELinux policies.
- Implement host baseline scanning using tools such as Lynis.

Always tailor the stack to match your organization’s security policies and compliance requirements.
