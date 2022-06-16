terraform {
  required_version = ">= 0.12" 
  
  required_providers {
    azurerm  = "~> 2.11"
    template = "~> 2.1.2"
    tls = "~> 2.1.1"
  }

  backend "azurerm" {} # Comment this line if executing locally
}

provider "azurerm" {
    features {}
}