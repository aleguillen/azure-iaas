# Azure IaaS Workshop

Workshop to deploy and manage Azure Infrastructure using Azure CLI. We will be using [Azure Cloud Shell](https://shell.azure.com) using Bash environment. To learn how to set it up see [here](https://docs.microsoft.com/en-us/azure/cloud-shell/quickstart). 

**TIP: To paste in Cloud Shell run: Ctrl + Shift + V.**

## Pre-requisites

### Set your subscription
```bash
az account list
```

To set your Azure Subscription, run:
```bash
az account set -s 'my-subscription-name-or-id'
```

To verify your Azure Subscription context, run:
```bash
az account show
```

### Clone repository

Clone this repository into your local. CloudShell already has Git install. Run:
```bash
git clone https://github.com/aleguillen/azure-iaas.git
```

Move to your repository working directory:
```bash
cd azure-iaas
```

Make sure you have right permissions to run files inside your repo's directory:
```bash
chmod 777 -R .
```

### [Create Base Infrastructure](./0-base.sh)

Before we get started, we need the follwowing base Azure infrastructure: Resource Group, Virtual Network with Subnets, Network Security Group, Internal and Public Load Balancer, Key Vault and Storage Account.

![](/.img/base.png)

To create your Base infrastructure run:
```bash
./0-base.sh
```

## [LAB 1 - Create a VMSS with Custom Script Extension](./1-vmss.sh)

Now that we have created the base infrastructure, we can create a VM behind the Public LB with an Extension to configure Html Hello World Page and a private VMSS behind the Internal LB.

![](/.img/vm-and-vmss.png)

If you want to use a Golden Image for your VMs, update 1-vmss.sh code Global Variables:
```bash
source ./set-variables.sh
```
with
```bash
source ./set-variables.sh -g "<my-image-resource-id>" 
```

To create your VM and VMSS run:
```bash
./1-vmss.sh
```

## [LAB 2 - Configure VMSS AutoScaling](./2-vmss-autoscaling.sh)

With your new VMSS we can now leverage features like AutoScaling. We are going to autoscale base on the Storage Messaging queue.

![](/.img/vm-and-vmss.png)

To configure your VMSS automatically run:
```bash
./2-vmss-autoscaling.sh
```

Check that 2 VMs will be created due to the default Overprovisioning setting set to true.
With overprovisioning turned on, the scale set actually spins up more VMs than you asked for, then deletes the extra VMs once the requested number of VMs are successfully provisioned. Overprovisioning improves provisioning success rates and reduces deployment time. You are not billed for the extra VMs, and they do not count toward your quota limits. 

To Scale down the VMSS with using AutoScaler rules, clear the queue by executing:
```bash
source ./set-variables.sh
az storage message clear -q wsqueue --account-name $STORAGE_ACCOUNT
```

## [LAB 3 - Configure Private Endpoint and VMSS SSH connectivity](./3-networking.sh)

To connect privately to your Storage Account or Key Vault we will create Private Endpoints. 
Additionally we will create a Private Link Service connected to the Internal LB to connect to the VMSS from the public available VM in VNET-01 using a Private Endpoint.

![](/.img/networking.png)

To configure your Private Endpoints automatically run:
```bash
./3-networking.sh
```

To SSH to your VMSS instances we will need to Jump into our VM (for demo purposes this is a public server). Then we will use the Private Endpoint (usually from another Network, but for demo purposes connected to the Private Link Service  
With overprovisioning turned on, the scale set actually spins up more VMs than you asked for, then deletes the extra VMs once the requested number of VMs are successfully provisioned. Overprovisioning improves provisioning success rates and reduces deployment time. You are not billed for the extra VMs, and they do not count toward your quota limits. 

To Scale down the VMSS with using AutoScaler rules, clear the queue by executing:
```bash
source ./set-variables.sh
az storage message clear -q wsqueue --account-name $STORAGE_ACCOUNT
```
