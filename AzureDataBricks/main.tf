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
# Create a Resource Group
resource "azurerm_resource_group" "rg" {
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
# Create a Two Subnet
# Create a Subnet within the Virtual Network
resource "azurerm_subnet" "public_subnet" {
  name                 = "${var.Databrick_workspace_name}-public-subnet"
  resource_group_name  = var.vnet_resourcegroup_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.1.65.0/26"]
    delegation {
        name = "databricks_public"
        service_delegation {
            name = "Microsoft.Databricks/workspaces"
        }
    }  
}
# Create a Subnet within the Virtual Network
resource "azurerm_subnet" "private_subnet" {
  name                 = "${var.Databrick_workspace_name}-private-subnet"
  resource_group_name  = var.vnet_resourcegroup_name
  virtual_network_name = var.vnet_name
  address_prefixes     = ["10.1.65.64/26"]
    delegation {
        name = "databricks_private"
        service_delegation {
            name = "Microsoft.Databricks/workspaces"
        }
    }  
}
#create NSG
resource "azurerm_network_security_group" "nsg" {
  name                = "${var.Databrick_workspace_name}-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}
resource "azurerm_subnet_network_security_group_association" "public" {
  depends_on = [ azurerm_subnet.public_subnet ]
  subnet_id                 = azurerm_subnet.public_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_subnet_network_security_group_association" "private" {
  depends_on = [ azurerm_subnet.private_subnet ]
  subnet_id                 = azurerm_subnet.private_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
# Create a Databrick Workspace
resource "azurerm_databricks_workspace" "databricks_workspace" {
  depends_on = [ azurerm_subnet_network_security_group_association.private, azurerm_subnet_network_security_group_association.public ]
  name                        = "${var.Databrick_workspace_name}-workspace"
  resource_group_name         = azurerm_resource_group.rg.name
  location                    = azurerm_resource_group.rg.location
  sku                         = "premium"
  public_network_access_enabled = "false"
  network_security_group_rules_required = "NoAzureDatabricksRules"
      custom_parameters {
        virtual_network_id  = var.vnet_id
        no_public_ip = "true"
        public_subnet_name  = "${var.Databrick_workspace_name}-public-subnet"
        private_subnet_name = "${var.Databrick_workspace_name}-private-subnet"
        public_subnet_network_security_group_association_id  = azurerm_subnet_network_security_group_association.public.id
        private_subnet_network_security_group_association_id = azurerm_subnet_network_security_group_association.private.id
      }
  managed_resource_group_name = "${var.Databrick_workspace_name}-workspace-rg"
  tags = {
    OwnerBCHO = "ET Rupinderjit"
    BCHOCostCenter  = "0000-0000-0000"
    Enviornment = "DEV"
    SolutionName  = "Terraform Testing databricks Environment"
    SolutionType  = "M"
    Project = "Terraform Testing"
  }   
}
#import the Private DNS zone 
data "azurerm_private_dns_zone" "dnsuiapi" {
  name                = "privatelink.azuredatabricks.net"
  resource_group_name = "fha-so-infra-net-001"
}
# Configure a Private Endpoint for the DataBrick Workspace databricks_ui_api
resource "azurerm_private_endpoint" "example_dnsuiapi" {
  name                = "${azurerm_databricks_workspace.databricks_workspace.name}-ui-api-PE"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = var.subnet_id
  private_dns_zone_group {
    name                 = "azurerm_databricks_workspace.databricks_workspace.name"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dnsuiapi.id]
  }
  private_service_connection {
    name                           = "${azurerm_databricks_workspace.databricks_workspace.name}-ui-api-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_databricks_workspace.databricks_workspace.id
    subresource_names              = ["databricks_ui_api"]
  }
}
# Configure a Private Endpoint for the DataBrick Workspace browser_authentication
# if canadacentral.pl-auth.privatelink.azuredatabricks.net is exist "is_manual_connection = true"
resource "azurerm_private_endpoint" "auth" {
  name                = "${azurerm_databricks_workspace.databricks_workspace.name}-auth-PE"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  subnet_id           = var.subnet_id
  
  private_dns_zone_group {
    name                 = "azurerm_databricks_workspace.databricks_workspace.name"
    private_dns_zone_ids = [data.azurerm_private_dns_zone.dnsuiapi.id]
  }
  private_service_connection {
    name                           = "${azurerm_databricks_workspace.databricks_workspace.name}-auth-psc"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_databricks_workspace.databricks_workspace.id
    subresource_names              = ["browser_authentication"]
  }
}
