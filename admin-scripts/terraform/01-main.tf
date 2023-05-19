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
  # Configuration options
}

locals {
    password = var.password
}