terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.75.0"
    }
  }
}

# Set the provider configuration for Azure
provider "azurerm" {
  skip_provider_registration = true
  features {}
}
resource "random_string" "random" {
    length = 6
    special = false
    upper = false
}

data "azurerm_private_dns_zone" "blob_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = "fha-so-infra-net-001"
}
data "azurerm_private_dns_zone" "dfs_zone" {
  name                = "privatelink.dfs.core.windows.net"
  resource_group_name = "fha-so-infra-net-001"
}

# Create a Resource Group
resource "azurerm_resource_group" "example" {
  name     = var.resource_group_name
  location = var.location  # Replace with your desired location
  tags = {
    OwnerBCHO = "ET Rupinderjit"
    BCHOCostCenter  = "0000-0000-0000"
    Enviornment = "DEV"
    SolutionName  = "Terraform Testing Environment"
    SolutionType  = "M"
    Project = "Terraform Testing"
  }  
}

# Create a Storage Account
resource "azurerm_storage_account" "example" {
  name                     = "${lower(var.storage_account_name)}${random_string.random.result}"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  public_network_access_enabled   = false #disbale public access
  is_hns_enabled                  = true #enable Hierarchical namespace
  }

  # Configure a Private Endpoint for the Storage Account
resource "azurerm_private_endpoint" "example_blob" {
  name                = "${azurerm_storage_account.example.name}-blob-PE"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = var.subnet_id
    private_dns_zone_group {
    name                 = "azurerm_storage_account.example.name"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.blob_zone.id]
  }

  private_service_connection {
    name                           = "${azurerm_storage_account.example.name}-blob-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["blob"]
  }
  
}
  # Configure a Private Endpoint for the Storage Account
resource "azurerm_private_endpoint" "example_dfs" {
  name                = "${azurerm_storage_account.example.name}-dfs-PE"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  subnet_id           = var.subnet_id
    private_dns_zone_group {
    name                 = "azurerm_storage_account.example.name"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dfs_zone.id]
  }
  private_service_connection {
    name                           = "${azurerm_storage_account.example.name}-dfs-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_storage_account.example.id
    subresource_names              = ["dfs"]
  }
}

