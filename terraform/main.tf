# GET: Current Azure RM context details
data "azurerm_client_config" "current" {}

# GET: Resource Group
data "azurerm_resource_group" "example" {
  name      = local.rg_name
}


data "azurerm_subnet" "example" {
  name                 = "private-snet"
  virtual_network_name = local.vnet_name
  resource_group_name  = local.rg_name
}

# GET: example Configuration cloudinit file. This can be converted to use an image.
data "template_file" "cloudinit" {
  template = file("${path.module}/scripts/cloudinit.sh")
}

data "template_cloudinit_config" "config" {
  gzip          = true
  base64_encode = true

  part {
    content = data.template_file.cloudinit.rendered
  }
}

# CREATE: Private/Public SSH Key for Linux Virtual Machine or VMSS
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}
