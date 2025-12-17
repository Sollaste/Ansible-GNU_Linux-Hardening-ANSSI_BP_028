output "resource_group_name" {
  description = "Nom du resource group"
  value       = azurerm_resource_group.main.name
}

output "ansible_master_public_ip" {
  description = "IP publique du serveur Ansible Master"
  value       = azurerm_public_ip.ansible_master.ip_address
}

output "ansible_master_private_ip" {
  description = "IP privée du serveur Ansible Master"
  value       = azurerm_network_interface.ansible_master.private_ip_address
}

output "node01_private_ip" {
  description = "IP privée de Node01"
  value       = azurerm_network_interface.node01.private_ip_address
}

output "node01_public_ip" {
  description = "IP publique de Node01"
  value       = azurerm_public_ip.node01.ip_address
}

output "ssh_command_node01" {
  description = "Commande SSH pour se connecter à Node01"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.node01.ip_address}"
}


output "ssh_command_ansible_master" {
  description = "Commande SSH pour se connecter à Ansible Master"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.ansible_master.ip_address}"
}

output "vnet_id" {
  description = "ID du Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "subnet_id" {
  description = "ID du Subnet"
  value       = azurerm_subnet.internal.id
}

output "ansible_master_vm_id" {
  description = "ID de la VM Ansible Master"
  value       = azurerm_linux_virtual_machine.ansible_master.id
}

output "node01_vm_id" {
  description = "ID de la VM Node01"
  value       = azurerm_linux_virtual_machine.node01.id
}
