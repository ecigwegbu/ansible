#!/bin/bash

# setup ansible for WinRM:

# Enter the ansible_password securely without typing it into the command line
read -s -p "Enter your password: " ansible_password
echo
# encrypt the ansible_password using same vault password stored in ~/.secrets/vpf, as you will need it later
# to decrypt it using the --vault-password-file option
# Hint: s-a-b-i-c
ansible-vault encrypt_string "$ansible_password" --name 'ansible_password' > ansible_passwd.yml
unset ansible_password  # for security reasons

# Sample ansible_password.yml file for the remote user when the password is 'student'
# Note that yml format is needed because the encryted content spans multiple lines
ansible_password: !vault |
          $ANSIBLE_VAULT;1.1;AES256
          30336638643661613830353532303864393334303566613631326565306233363938383230323561
          3762313765303062633631353332306565356131333566390a616535393063663562313261363932
          34383236393137346662343564396632373566346532666530616430343966303137646261316364
          6162343063316364630a343661616638643665396561303462343965366131613066643764396566
          6330

# Sample inventory file:
[win]
192.168.56.254

[win:vars]
ansible_user=student
ansible_port=5986
ansible_connection=winrm
ansible_winrm_scheme=https
ansible_winrm_server_cert_validation=ignore

# Ansible config file sessentially unchanged from SSH style (had no impact on WinRM when removed entirely):
[defaults]
inventory=inventory
remote_user=student
ask_pass=false
become=false
become_ask_pass=false
become_method=sudo
become_user=root

# Run the ansible ad-hoc command
# ansible win -i inventory -m win_ping --extra-vars "@ansible_password.yml" --vault-password-file='~/.secrets/vpf'
[student@rhel9-win winrm]$ ansible win --extra-vars "@ansible_password.yml" --vault-password-file ~/.secrets/vpf -m win_ping          192.168.56.254 | SUCCESS => {
    "changed": false,
    "ping": "pong"
}
[student@rhel9-win winrm]$
