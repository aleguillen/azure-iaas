locals {
  # Following Azure Naming Conventions: 
  # https://docs.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/naming-and-tagging

  # General
  naming_conv = "${var.environment_name}-${var.location}"
  
  unique_rg_string = md5(data.azurerm_resource_group.example.id)
  
  rg_name   = "${local.naming_conv}-rg"

  vnet_name   = "${local.naming_conv}-vnet-02"

  vmss_name   = "${local.naming_conv}-tf-vmss"

  nic_name   = "nic-vm-${local.naming_conv}-ado"

  # Terraform
  storage_account_name = "${var.environment_name}${substr(local.unique_rg_string,0,5)}sa"
  
  tf_container_name = "terraform"


}
