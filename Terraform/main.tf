terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
    }
  }

  # Backend configuration pour stocker le state dans Azure Storage
  # À décommenter après avoir créé le storage account manuellement
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "tfstateanssi"
  #   container_name       = "tfstate"
  #   key                  = "ansible-hardening.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }

    virtual_machine {
      delete_os_disk_on_deletion     = true
      skip_shutdown_and_force_delete = false
    }
  }

  subscription_id = "d18efcbe-caa9-4004-ac2c-7312261e11de"
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}"
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags
}

# Subnet
resource "azurerm_subnet" "internal" {
  name                 = "snet-internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = [var.subnet_address_prefix]
}

# Network Security Group pour Ansible Master
resource "azurerm_network_security_group" "ansible_master" {
  name                = "nsg-ansible-master"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
    description                = "Allow SSH from authorized IPs"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }


  # Allow outbound
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Network Security Group pour Node01
resource "azurerm_network_security_group" "node" {
  name                = "nsg-node"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  # Allow outbound for only you're IP
  security_rule {
    name                       = "AllowSSHInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefixes    = var.allowed_ip_ranges
    destination_address_prefix = "*"
    description                = "Allow SSH from authorized IPs"
  }

  # Deny all other inbound traffic
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow outbound
  security_rule {
    name                       = "AllowAllOutbound"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Public IP pour Ansible Master
resource "azurerm_public_ip" "ansible_master" {
  name                = "pip-ansible-master"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Public IP pour Node01
resource "azurerm_public_ip" "node01" {
  name                = "pip-node01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}



# Network Interface pour Ansible Master
resource "azurerm_network_interface" "ansible_master" {
  name                = "nic-ansible-master"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.ansible_master.id
  }
}

# Network Interface pour Node01
resource "azurerm_network_interface" "node01" {
  name                = "nic-node01"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id = azurerm_public_ip.node01.id
  }
}

# Association NSG - NIC Ansible Master
resource "azurerm_network_interface_security_group_association" "ansible_master" {
  network_interface_id      = azurerm_network_interface.ansible_master.id
  network_security_group_id = azurerm_network_security_group.ansible_master.id
}

# Association NSG - NIC Node01
resource "azurerm_network_interface_security_group_association" "node01" {
  network_interface_id      = azurerm_network_interface.node01.id
  network_security_group_id = azurerm_network_security_group.node.id
}

# VM Ansible Master
resource "azurerm_linux_virtual_machine" "ansible_master" {
  name                  = "ansible-master01"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.ansible_master.id]
  size                  = var.vm_size
  tags                  = var.tags

  os_disk {
    name                 = "osdisk-ansible-master"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Debian 13 Trixie - Image depuis Azure Marketplace
  source_image_reference {
    publisher = "Debian"
    offer     = "debian-13"
    sku       = "13-gen2"
    version   = "latest"
  }

  # Alternative si l'image ci-dessus n'est pas disponible, utiliser Debian 12 puis upgrade
  # source_image_reference {
  #   publisher = "debian"
  #   offer     = "debian-12"
  #   sku       = "12"
  #   version   = "latest"
  # }

  computer_name                   = "ansible-master01"
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  # Script d'initialisation pour installer Ansible
  custom_data = base64encode(templatefile("${path.module}/scripts/init-ansible-master.sh", {
    node01_ip = azurerm_network_interface.node01.private_ip_address
    admin_username = var.admin_username
  }))

  identity {
    type = "SystemAssigned"
  }
}

# VM Node01
resource "azurerm_linux_virtual_machine" "node01" {
  name                  = "node01"
  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  network_interface_ids = [azurerm_network_interface.node01.id]
  size                  = var.vm_size
  tags                  = var.tags

  os_disk {
    name                 = "osdisk-node01"
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  # Debian 13 Trixie
  source_image_reference {
    publisher = "Debian"
    offer     = "debian-13"
    sku       = "13-gen2"
    version   = "latest"
  }

  computer_name                   = "node01"
  admin_username                  = var.admin_username
  disable_password_authentication = true

  admin_ssh_key {
    username   = var.admin_username
    public_key = file(var.ssh_public_key_path)
  }

  identity {
    type = "SystemAssigned"
  }
}

