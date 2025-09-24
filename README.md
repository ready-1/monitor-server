# monitor-server
Network Monitor Server

## Ansible Deployment

The `ansible.cfg` file is configured to use sudo for privilege escalation. When running the playbook, you'll be prompted for the sudo password.

Run the main playbook with:
```
ansible-playbook -i inventory.ini site.yml -vv
```

If you want to provide the sudo password in the command line (useful for scripting), use:
```
ansible-playbook -i inventory.ini site.yml -vv --ask-become-pass
```

Use `-vv` for verbose output to troubleshoot connectivity issues.

Note: Ensure that your target hosts are configured to allow sudo access for the `monitor` user.
