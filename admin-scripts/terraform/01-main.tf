terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.57.0"
    }
    azuread = {
      source = "hashicorp/azuread"
      version = "2.39.0"
    }
  }
}

provider "azurerm" {
  features {
    
  }
}

locals {
    password = var.password
}

data "azurerm_subscription" "primary" {
}

data "azurerm_client_config" "example" {
}

data "azuread_client_config" "current" {}

data "azuread_domains" "example" {
  only_initial = true
}