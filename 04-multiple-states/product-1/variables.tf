variable "vm_username" {
  type        = string
  description = "Username for vm-1"
}

variable "vm_password" {
  type        = string
  sensitive   = true
  description = "Password for vm-1"
}