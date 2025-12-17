#!/bin/bash
set -e

# Mise à jour du système
apt-get update
apt-get upgrade -y

# Installation d'Ansible
apt-get install -y ansible python3-pip git

# Configuration SSH pour Ansible
mkdir -p /home/${admin_username}/.ssh
chmod 700 /home/${admin_username}/.ssh

# Création du fichier inventory Ansible
cat > /etc/ansible/hosts << EOF
[managed_nodes]
node01 ansible_host=${node01_ip} ansible_user=${admin_username}

[all:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

# Installation de collections Ansible utiles
ansible-galaxy collection install community.general ansible.posix

echo "Ansible Master initialized successfully"
