variable "vm_username" {
  type        = string
  description = "Username of the VM."
}

variable "vm_password" {
  type        = string
  description = "Password of the VM."
  sensitive   = true
}
