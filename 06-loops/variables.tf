variable "base_name" {
  type        = string
  description = "Base name used for resource names."
}

variable "nb_of_spokes" {
  type        = number
  description = "Number of VNET spokes to create."
}

variable "nsg_rules" {
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  description = "List of rules to use for the network security group."
}
