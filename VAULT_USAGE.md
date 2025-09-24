# Ansible Vault Usage Guide

This guide explains how to use Ansible Vault with our current configuration.

## Configuration Overview

Our `ansible.cfg` is set up with the following Vault-related settings:

```ini
# Primary: Use .vault_password file if present (created manually by user)
vault_password_file = .vault_password

# Fallback: Prompt for password if .vault_password file is missing
vault_identity_list = default@.vault_password, default@prompt
```

## Setup Instructions

1. Create a `.vault_password` file in the project root:
   ```bash
   echo "your_vault_password" > .vault_password
   ```

2. Secure the file (readable only by owner):
   ```bash
   chmod 600 .vault_password
   ```

3. Verify that `.vault_password` is listed in your `.gitignore` file to prevent accidental commits.

## Usage Scenarios

### 1. Automated/CI Environments
- Ensure the `.vault_password` file is present with the correct password and proper permissions.
- Ansible will automatically use this file for decryption.

### 2. Interactive Development
- If you prefer to be prompted for the password, simply delete or rename the `.vault_password` file.
- Ansible will then prompt you for the password when needed.

### 3. Override Scenarios
- To use a different password or method, you can override the config:
  ```bash
  ansible-playbook --vault-id custom_id@prompt site.yml
  ```

## Working with Encrypted Files

### Encrypting a File
```bash
ansible-vault encrypt path/to/file.yml
```

### Editing an Encrypted File
```bash
ansible-vault edit path/to/file.yml
```

### Viewing an Encrypted File
```bash
ansible-vault view path/to/file.yml
```

### Decrypting a File
```bash
ansible-vault decrypt path/to/file.yml
```

## Best Practices

1. Always encrypt sensitive data before committing to version control.
2. Regularly rotate your vault password for enhanced security.
3. Use different vault passwords for different environments (dev, staging, prod).
4. When working in a team, consider using a secure method to share the vault password.

Remember, the `.vault_password` file should never be committed to version control. Each team member or environment should manage this file independently.
