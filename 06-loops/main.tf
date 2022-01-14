terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }

  backend "azurerm" {
    resource_group_name  = "rg-tfstate-cac"
    storage_account_name = "satfstatecac0001"
    container_name       = "state"
    key                  = "loops.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.base_name}-cac"
  location = "canadacentral"
}

resource "azurerm_virtual_network" "hub" {
  name                = "vnet-${var.base_name}-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  subnet {
    name           = "default"
    address_prefix = "10.0.0.0/24"
  }
}

resource "azurerm_virtual_network" "spokes" {
  count               = var.nb_of_spokes
  name                = "vnet-${var.base_name}-spoke-${count.index + 1}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.${count.index + 1}.0.0/16"]

  subnet {
    name           = "default"
    address_prefix = "10.${count.index + 1}.0.0/24"
  }
}

resource "azurerm_virtual_network_peering" "hub_to_spoke" {
  for_each                  = { for vnet in azurerm_virtual_network.spokes : vnet.name => vnet.id }
  name                      = "hub-to-${each.key}"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = each.value
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke_to_hub" {
  for_each                  = { for vnet in azurerm_virtual_network.spokes : vnet.name => vnet.id }
  name                      = "${each.key}-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = each.key
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

resource "azurerm_network_security_group" "nsg" {
  name                = "nsg-${var.base_name}-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  dynamic "security_rule" {
    for_each = var.nsg_rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
}
