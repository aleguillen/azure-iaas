variable "environment_name" {
  type        = string
  description = "Environment Name."
  default     = "workshop"
}

variable "location" {
  type        = string
  description = "The Azure region where your resources will be created."
  default = "eastus2"
}

variable "vmss_instances" {
  type        = number
  description = "specified the number of instances for the VMSS. Default is 2."
  default     = 2
}

variable "vm_username" {
  type        = string
  description = "The username for the VM."
  default = "azuresuser"
}

variable "vm_password" {
  type        = string
  description = "The password for the VM."
  default     = ""
}

variable "vm_image_id" {
  type        = string
  description = "The VM Image Id to use for the  VMSS."
  default     = ""
}

variable "vm_size" {
  type        = string
  description = "The VM Size to use for the VMSS."
  default     = "Standard-DS1_v2"
}