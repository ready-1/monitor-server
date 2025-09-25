# Ansible Vault Usage Guide

This guide explains how Vault is configured in the Monitor Server project and how to manage encrypted data safely.

---

## Configuration Overview

`ansible.cfg` contains the following Vault-related settings:

```ini
# Use .vault_password file if present (created manually by user)
vault_password_file = .vault_password
```

If the file exists, Ansible reads the vault password from it. If it is missing, Ansible will prompt for a password when needed.

---

## Setup Instructions

1. Create a `.vault_password` file in the project root (never commit this file):
   ```bash
   echo "your_vault_password" > .vault_password
   chmod 600 .vault_password
   ```

2. Verify that `.vault_password` is listed in `.gitignore`.

3. (Optional) If you prefer being prompted instead of using the file, remove or rename `.vault_password` and run plays with `--ask-vault-pass`.

---

## Working with Encrypted Files

Encrypted data currently resides in `group_vars/all/become_vars.yml`. Use Ansible Vault commands to view or modify it:

| Action | Command |
| --- | --- |
| Encrypt a file | `ansible-vault encrypt path/to/file.yml` |
| Edit an encrypted file | `ansible-vault edit path/to/file.yml` |
| View an encrypted file | `ansible-vault view path/to/file.yml` |
| Decrypt a file | `ansible-vault decrypt path/to/file.yml` |
| Change the vault password | `ansible-vault rekey path/to/file.yml` |

---

## Best Practices

1. **Never commit the vault password**: `.vault_password` should remain local to your control node.
2. **Rotate passwords regularly**: Use `ansible-vault rekey` to update the password and share the new secret securely with teammates.
3. **Use different vault passwords per environment**: For example, maintain separate vault files for development, staging, and production.
4. **Audit encrypted content**: Store only sensitive values in vaulted files; keep non-sensitive defaults in plaintext vars.

---

## Advanced Usage

To override the default password source or use multiple vault IDs, rely on Ansible’s CLI options. Examples:

- Prompt for the vault password even if `.vault_password` exists:

  ```bash
  ansible-playbook --ask-vault-pass site.yml
  ```

- Specify an alternate vault file:

  ```bash
  ansible-playbook --vault-id myenv@prompt site.yml
  ```

- Mix multiple sources:

  ```bash
  ansible-playbook --vault-id default@.vault_password --vault-id prod@prompt site.yml
  ```

Adjust these patterns to match your team’s secret management policies.
