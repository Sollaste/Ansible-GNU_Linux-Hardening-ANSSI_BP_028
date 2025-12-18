variable "project_name" {
  description = "Nom du projet utilisé pour le préfixe des ressources"
  type        = string
  default     = "anssi-bp-028"
}

variable "environment" {
  description = "Environnement de déploiement"
  type        = string
  default     = "production"

  validation {
    condition     = contains(["dev", "staging", "production"], var.environment)
    error_message = "L'environnement doit être dev, staging ou production."
  }
}

variable "location" {
  description = "Région Azure pour le déploiement"
  type        = string
  default     = "westeurope"
}

variable "admin_username" {
  description = "Nom d'utilisateur administrateur pour les VMs"
  type        = string
  default     = "azureadmin"
}

variable "ssh_public_key_paths" {
  description = "Chemin vers la clé publique SSH"
  type        = list(string)
  default     = []
}

variable "allowed_ip_ranges" {
  description = "Plages IP autorisées pour SSH (votre IP publique)"
  type        = list(string)
  default     = []
}


variable "vm_size" {
  description = "Taille des machines virtuelles"
  type        = string
  default     = "Standard_D2s_v3"
}

variable "vnet_address_space" {
  description = "Espace d'adressage du Virtual Network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_address_prefix" {
  description = "Préfixe d'adresse du subnet"
  type        = string
  default     = "10.0.1.0/24"
}

variable "tags" {
  description = "Tags à appliquer aux ressources"
  type        = map(string)
  default = {
    Project   = "ANSSI-BP-028"
    ManagedBy = "Terraform"
    Purpose   = "Ansible-Hardening"
  }
}
