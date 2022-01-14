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
    key                  = "product1.terraform.tfstate"
  }
}

provider "azurerm" {
  features {}
}

data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    resource_group_name  = "rg-tfstate-cac"
    storage_account_name = "satfstatecac0001"
    container_name       = "state"
    key                  = "network.terraform.tfstate"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-product1-cac"
  location = "canadacentral"
}

module "vm1" {
  source = "./modules/windows-vm"

  install_iis         = true
  location            = azurerm_resource_group.rg.location
  name                = "vm-product-001"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.terraform_remote_state.network.outputs.spoke1_snet1_id
  vm_username         = var.vm_username
  vm_password         = var.vm_password
}

module "vm2" {
  source = "./modules/windows-vm"

  install_iis         = false
  location            = azurerm_resource_group.rg.location
  name                = "vm-product-002"
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = data.terraform_remote_state.network.outputs.spoke2_snet1_id
  vm_username         = var.vm_username
  vm_password         = var.vm_password
}

