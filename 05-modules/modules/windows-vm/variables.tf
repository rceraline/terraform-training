variable "install_iis" {
  type        = bool
  description = "Determine if IIS should be install on the VM."
  default     = false
}

variable "location" {
  type        = string
  description = "Location of the VM."
}

variable "name" {
  type        = string
  description = "Name of the VM."
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet where the VM should be deployed."
}

variable "vm_username" {
  type        = string
  description = "Username of the VM."
}

variable "vm_password" {
  type        = string
  description = "Password of the VM."
  sensitive   = true
}
