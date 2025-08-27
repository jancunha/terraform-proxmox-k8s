# --- Variáveis --- 
# Para usar, crie um arquivo terraform.tfvars ou passe na linha de comando.

variable "ci_user" {
  description = "Nome de usuário para o cloud-init."
  type        = string
  default     = "sysadmin"
}

variable "ci_password" {
  description = "Senha para o cloud-init."
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Chave SSH pública para autorizar o acesso."
  type        = string
  sensitive   = true
}

variable "ssh_private_key_path" {
  description = "Caminho para o arquivo da chave SSH privada para o provisionamento."
  type        = string
}

variable "template_name" {
  description = "Nome do template."
  type        = string
  default     = "ubuntu-2204-cloud-init-tf"
}

variable "proxmox_node" {
  description = "Nome do nó Proxmox onde a VM será criada."
  type        = string
  default     = "pve"

}