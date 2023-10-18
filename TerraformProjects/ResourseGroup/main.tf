terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.75.0"
    }
  }
}

provider "azurerm" {
  features {
    
  }
}
# data "azurerm_resource_group" "example_azurerm_resource_group"{
#   name = "ET-Terraform-RG"
# }
# output "id" {
#   value = data.azurerm_resource_group.example_azurerm_resource_group.id
# }

resource "azurerm_resource_group" resource_group {
  name     = "ET-Terraform-RG"
  location = "Canada Central"
  tags = {
    OwnerBCHO = "ET Rupinderjit"
    BCHOCostCenter  = "0000-0000-0000"
    Enviornment = "DEV"
    SolutionName  = "Terraform Testing Environment"
    SolutionType  = "M"
    Project = "Terraform Testing"
  }
}