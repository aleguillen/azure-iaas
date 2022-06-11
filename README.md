# Azure IaaS Workshop

Workshop to deploy and manage Azure Infrastructure using Azure CLI. We will be using [Azure Cloud Shell](https://shell.azure.com) using Bash environment. To learn how to set it up see [here](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart). 

**TIP: To paste in Cloud Shell run: Ctrl + Shift + V.**

## Pre-requisites

### Set your subscription
```bash
az account list
```

```bash
az account set -s 'my-subscription-name-or-id'
```

### Clone repo into Cloud Shell

```bash
git clone https://github.com/aleguillen/azure-iaas.git
cd azure-iaas
chmod 777 -R .
```

### [Create Base Infrastructure](./0.sh)

```bash
./0.sh
```

This script creates the follwoing base Azure infrastructure: Resource Group, Virtual Network with Subnets, Network Security Group, Internal and Public Load Balancer, Key Vault and Storage Account.

## [LAB 1 - Create a VMSS with Custom Script Extension](./1.sh)
```bash
./1.sh
```

