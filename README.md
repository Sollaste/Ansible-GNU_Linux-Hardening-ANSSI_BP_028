
# Ansible-GNU_Linux-Hardening-ANSSI_BP_028

Infrastructure-as-code and Ansible content to automate GNU/Linux hardening based on the ANSSI BP-028 recommendations. This repository aims to provide a reproducible, **compliance-as-code** baseline for secure system configuration.

---

## Features

- Automated provisioning of a minimal Azure environment for hardened Linux hosts
- Opinionated security baseline aligned with ANSSI BP-028
- Separation between infrastructure (Terraform) and configuration (Ansible)
- SSH key-based access only, with tightly restricted network security rules

---

## Repository structure
```
.
├── Terraform/
│ ├── main.tf # Azure resources (RG, VNet, NSG, NICs, IPs, VMs)
│ ├── variables.tf # Input variables
│ ├── outputs.tf # Useful outputs (IPs, SSH commands, etc.)
│ ├── terraform.tfvars.example # Example variable file (no secrets)
│ └── scripts/
│ └── init-ansible-master.sh # Bootstrap script for Ansible master
└── ansible/
├── inventory.ini # Ansible inventory example
├── hardening.yml # Main hardening playbook
└── roles/ # Roles implementing ANSSI BP-028 controls
└── ...
```

Adjust paths/names if your tree differs.

---

## Prerequisites

- Active **Azure subscription**
- **Terraform** (v1.5+ recommended)
- **Azure CLI** installed and logged in
- **Ansible** installed (locally or on the Ansible master VM)
- An **SSH key pair** generated for VM access, for example:

```
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa
```
or
```
ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519
```

---

## Getting started

### 1. Clone the repository

```
git clone https://github.com/Sollaste/Ansible-GNU_Linux-Hardening-ANSSI_BP_028.git
```
```
cd Ansible-GNU_Linux-Hardening-ANSSI_BP_028/Terraform
```

### 2. Configure Terraform variables

Use the example file as a safe template:

```
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and set at least:

```
subscription_id = "XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX"
location = "westeurope"
admin_username = "azureadmin"
ssh_public_key_path = "C:/Users/you/.ssh/id_rsa.pub"

allowed_ip_ranges = [
"X.X.X.X/32", # your public IP
]
```
Optionally override:
vnet_address_space, subnet_address_prefix, vm_size, tags, ...
text

> **Important:** Do not commit `terraform.tfvars`. Only keep `terraform.tfvars.example` in Git.

### 3. Deploy the Azure infrastructure

Authenticate to Azure
```
az login
```
```
az account set --subscription "<SUBSCRIPTION_ID>"
```

From the Terraform directory
- terraform init
- terraform validate
- terraform plan
- terraform apply



Terraform will create:

- Resource group, virtual network and subnet
- Network Security Groups with restrictive inbound rules (SSH only from your IPs)
- Public IPs and NICs
- An **Ansible master** VM and at least one **Linux node** VM

---

## Accessing the VMs

After `terraform apply`, check the outputs:

```
terraform output
```

if defined:
```
terraform output ssh_command_ansible_master
```
```
terraform output ssh_command_node01
```

Example usage:

```
ssh azureadmin@<ANSIBLE_MASTER_PUBLIC_IP>
ssh azureadmin@<NODE01_PUBLIC_IP>
```


Authentication is done with your SSH private key only; password logins are disabled by design.

---

## Running the Ansible hardening

### 1. Example inventory

From the repository root:

ansible/inventory.ini
```
[ansible_master]
ansible-master ansible_host=<ANSIBLE_MASTER_PUBLIC_IP>

[linux_nodes]
node01 ansible_host=<NODE01_PUBLIC_IP>

[all:vars]
ansible_user=azureadmin
ansible_ssh_private_key_file=~/.ssh/id_rsa
```

### 2. Execute the hardening playbook
```
cd ansible
```
```
ansible-playbook -i inventory.ini hardening.yml
```

The playbook and roles are expected to implement ANSSI BP-028 controls, such as:

- SSH daemon hardening
- Logging, auditing and journal retention
- Service minimisation and network restrictions
- File permissions, users/groups, sudo configuration, etc.

---

## Security best practices

**Never commit:**

- `terraform.tfvars` or any real `*.tfvars` file
- Terraform state files: `terraform.tfstate`, `*.tfstate.backup`, etc.
- Private SSH keys: `id_rsa`, `id_ed25519`, `*.pem`, `*.key`, etc.

Ensure your `.gitignore` includes at least:

Terraform
*.tfstate
.tfstate.
.terraform/
.terraform.lock.hcl
terraform.tfvars
.tfvars
!.tfvars.example
*.tfplan

SSH keys
*.pem
*.key
*.ppk
id_rsa
id_ed25519
.ssh/

IDE / OS noise
.idea/
.vscode/
.DS_Store
Thumbs.db


Use **tight CIDR ranges** in `allowed_ip_ranges` (ideally your fixed IP or VPN).

Destroy lab environments when not needed to reduce cost and exposure:

terraform destroy


---

## License

Specify the license you want to use (e.g. `MIT`, `Apache-2.0`, `GPL-3.0`) and place the corresponding `LICENSE` file at the root of the repository.

