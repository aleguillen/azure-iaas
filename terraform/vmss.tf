#############################
# CREATE: Linux VMSS Agent  #
#############################

# CREATE: Azure Linux VMSS 
resource "azurerm_linux_virtual_machine_scale_set" "example" {

  name                  = local.vmss_name
  location              = data.azurerm_resource_group.example.location
  resource_group_name   = data.azurerm_resource_group.example.name
  sku                   = var.vm_size

  instances             = var.vmss_instances
  upgrade_mode          = "Manual"
  overprovision = false 

  zones = [1, 2, 3]

  admin_username = var.vm_username
  disable_password_authentication = length(var.vm_password) > 0 ? false : true
  admin_password =  length(var.vm_password) > 0 ? var.vm_password : null

  dynamic "admin_ssh_key" {
    for_each = length(var.vm_password) > 0 ? [] : [var.vm_username]
    content {
      username   = var.vm_username
      public_key = tls_private_key.example.public_key_openssh
    }
  }

  # Cloud Init Config file
  custom_data = data.template_cloudinit_config.config.rendered

  # If vm_image_id is specified will use this instead of source_image_reference default settings
  source_image_id =  length(var.vm_image_id) > 0 ? var.vm_image_id : null
  
  dynamic "source_image_reference" {
    for_each = length(var.vm_image_id) > 0 ? [] : [1]
    content {
      publisher = "Canonical"
      offer     = "UbuntuServer"
      sku       = "18.04-LTS"
      version   = "latest"
    }
  }

  os_disk {
    caching               = "ReadWrite"
    storage_account_type  = "Standard_LRS"
  }

  network_interface {
    name    = local.nic_name
    primary = true

    ip_configuration {
      name      = "ipconfig1"
      primary   = true
      subnet_id = data.azurerm_subnet.example.id
    }
  }

  identity {
    type = "SystemAssigned"
  }

  
}