terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-terraform-cac"
  location = "canadacentral"
}

resource "null_resource" "search" {
  triggers = {
    environment         = "dev"
    resource_group_name = azurerm_resource_group.rg.name
  }

  provisioner "local-exec" {
    when    = create
    command = "az search service create --location canadacentral --name terra-${self.triggers.environment}-srch --resource-group ${self.triggers.resource_group_name} --sku free"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "az search service delete --name terra-${self.triggers.environment}-srch --resource-group ${self.triggers.resource_group_name} --yes"
  }
}
