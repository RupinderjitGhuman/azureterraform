# Define variables
variable "resource_group_name" {
  description = "Name of the Azure Resource Group"
  type        = string
}

variable "storage_account_name" {
  description = "Name of the Azure Storage Account"
  type        = string
}

variable "location" {
  description = "Location for the deployment"
  type        = string
}
variable "vnet_id" {
  description = "ID of an existing virtual network subnet"
  type        = string
}
variable "vnet_name" {
  description = "virtual network name"
  type        = string
}
variable "vnet_resourcegroup_name" {
  description = "resource Group name of Vnet"
  type        = string
}

variable "subnet_id" {
  description = "ID of an existing virtual network subnet"
  type        = string
}
variable "Databrick_workspace_name" {
  description = "ID of an existing virtual network subnet"
  type        = string
}
