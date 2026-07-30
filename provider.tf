terraform {
  cloud {
    organization = "mengdanzhao-org"
    hostname     = "app.terraform.io"
    workspaces {
      name = "learn-terraform-azurerm"
    }
  }
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
