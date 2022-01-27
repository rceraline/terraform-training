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
    key                  = "network.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}


resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-cac"
  location = "canadacentral"
}

### vnets & subnets ###
resource "azurerm_virtual_network" "hub" {
  name                = "vnet-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "hub_subnet1" {
  name                 = "snet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_virtual_network" "spoke1" {
  name                = "vnet-spoke-1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "spoke1_subnet1" {
  name                 = "snet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke1.name
  address_prefixes     = ["10.1.0.0/24"]
}

resource "azurerm_virtual_network" "spoke2" {
  name                = "vnet-spoke-2"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.2.0.0/16"]
}

resource "azurerm_subnet" "spoke2_subnet1" {
  name                 = "snet-1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke2.name
  address_prefixes     = ["10.2.0.0/24"]
}

### vnet peerings ###
resource "azurerm_virtual_network_peering" "hub_to_spoke1" {
  name                      = "hub-to-spoke1"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke1.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke1-to-hub" {
  name                      = "spoke1-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke1.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke2" {
  name                      = "hub-to-spoke2"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.hub.name
  remote_virtual_network_id = azurerm_virtual_network.spoke2.id
  allow_forwarded_traffic   = true
  allow_gateway_transit     = true
}

resource "azurerm_virtual_network_peering" "spoke2-to-hub" {
  name                      = "spoke2-to-hub"
  resource_group_name       = azurerm_resource_group.rg.name
  virtual_network_name      = azurerm_virtual_network.spoke2.name
  remote_virtual_network_id = azurerm_virtual_network.hub.id
  allow_forwarded_traffic   = true
}

### Azure Firewall ###
resource "azurerm_subnet" "firewall" {
  name                 = "AzureFirewallSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_public_ip" "firewall_pip" {
  name                = "pip-terraform-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_firewall" "firewall" {
  name                = "afw-terraform-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.firewall.id
    public_ip_address_id = azurerm_public_ip.firewall_pip.id
  }
}

### Firewall rules ###
resource "azurerm_firewall_network_rule_collection" "allow_all" {
  name                = "network-rule"
  azure_firewall_name = azurerm_firewall.firewall.name
  resource_group_name = azurerm_resource_group.rg.name
  priority            = 100
  action              = "Allow"

  rule {
    name = "allow-all"

    source_addresses = [
      "10.0.0.0/16",
      "10.1.0.0/16",
      "10.2.0.0/16",
    ]

    destination_ports = [
      "*",
    ]

    destination_addresses = [
      "*",
    ]

    protocols = [
      "TCP",
      "UDP",
    ]
  }
}

### route tables ###
resource "azurerm_route_table" "to_spoke2" {
  name                = "rt-terraform-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "to-spoke2"
    address_prefix         = "10.2.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_route_table" "to_spoke1" {
  name                = "rt-terraform-002"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  route {
    name                   = "to-spoke1"
    address_prefix         = "10.1.0.0/16"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = azurerm_firewall.firewall.ip_configuration[0].private_ip_address
  }
}

resource "azurerm_subnet_route_table_association" "spoke1" {
  subnet_id      = azurerm_subnet.spoke1_subnet1.id
  route_table_id = azurerm_route_table.to_spoke2.id
}

resource "azurerm_subnet_route_table_association" "spoke2" {
  subnet_id      = azurerm_subnet.spoke2_subnet1.id
  route_table_id = azurerm_route_table.to_spoke1.id
}

### Bastion ###
resource "azurerm_subnet" "bastion" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/27"]
}

resource "azurerm_public_ip" "bas" {
  name                = "pip-network-cac-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_bastion_host" "bas" {
  name                = "bas-network-cac-001"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion.id
    public_ip_address_id = azurerm_public_ip.bas.id
  }
}
