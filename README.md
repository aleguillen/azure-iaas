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

To open VS Code in Cloud Shell, for easy file management, run:
```bash
code .
```

### [Create Base Infrastructure](./0-base.sh)

Before we get started, we need the follwowing base Azure infrastructure: Resource Group, Virtual Network with Subnets, Network Security Group, Internal and Public Load Balancer, Key Vault and Storage Account.

![](/.img/base.png)

To create your Base infrastructure run:
```bash
./0-base.sh
```

## [LAB 1 - Create a VMSS with Custom Script Extension](./1-vmss.sh)

Now that we have created our base infrastructure, we can create a VM behind the Public LB with an Extension to configure Html Hello World Page and a private VMSS behind the Internal LB.

For this lab, I recommend using a **Golden Image** with a **specific version** (but do not select the latest version number). In my case I have an Ubuntu image definition in my Azure Compute Gallery with 2 versions: 1.0.0 and 1.0.1, I will use for this lab 1.0.0. 

In case you don't have a Golden Image, the latest Azure Marketplace Ubuntu image will be use. Note, that lab 4 may be slightly impacted.

![](/.img/vm-and-vmss.png)

If you want to use a Golden Image for your VMs, update **1-vmss.sh** code Global Variables. From:
```bash
source ./set-variables.sh
```
to
```bash
source ./set-variables.sh -g "/subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>/providers/Microsoft.Compute/galleries/<GALLERY_NAME>/images/IMG_DEF/versions/1.0.0"
```

To create your VM and VMSS run:
```bash
./1-vmss.sh
```

Note that Virtual Machine is using Custom Script to configura NGINX Welcome Page, and VMSS is using Cloud Init to do the same. To test both are setup correctly, we can use Run-Command to curl inside the servers (this code is already  part of 1-vmss.sh script, however you can run it several times for testing)

```bash
source ./set-variables.sh

echo "Testing using Run-Command Welcome page - From VM"
az vm run-command invoke \
  -g $RG_NAME \
  -n $VM_NAME \
  --command-id RunShellScript \
  --scripts "curl localhost"

echo "Testing using Run-Command Welcome page - From VMSS"
INSTANCE_ID=$(az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output tsv --query [0].instanceId)

az vmss run-command invoke \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --instance-id $INSTANCE_ID \
  --command-id RunShellScript \
  --scripts "curl localhost" 

```

## [LAB 2 - Configure VMSS AutoScaling](./2-vmss-autoscaling.sh)

With your new VMSS we can now leverage features like AutoScaling. We are going to autoscale base on the Storage Messaging queue.

To configure your VMSS automatically run:
```bash
./2-vmss-autoscaling.sh
```

Check that 2 VMs will be created due to the default Overprovisioning setting set to true.
With overprovisioning turned on, the scale set actually spins up more VMs than you asked for, then deletes the extra VMs once the requested number of VMs are successfully provisioned. Overprovisioning improves provisioning success rates and reduces deployment time. You are not billed for the extra VMs, and they do not count toward your quota limits. 

**To Scale down the VMSS with using AutoScaler rules, clear the queue by executing:**
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

To SSH to your VMSS instances we will need to Jump into our VM in VNET-01. Then use the Private Endpoint's IP address from VNET-01 to connect to our VMSS, passing through our Private Link Service, then Internal Load Balancer until finally hit or VMSS located in VNET-02 (Connectivity path: VM -> PE -> PLS -> ILB -> VMSS).

**To check you are using Private Endpoint to connect to your Storage Account you can use nslookup to your Storage Account, you should see a Private IP resolution from your Private DNS Zone.**
```bash
source ./set-variables.sh
nslookup "$STORAGE_ACCOUNT.blob.core.windows.net"
```

If you want to test MSI authentication with Private Endpoint access to your storage account you can run the following command (mak sure all REPLACE-ME tags are updated), inside the VMSS SSH console.
```bash
STORAGE_ACCOUNT=<REPLACE_ME>
SUB_ID=<REPLACE_ME>
RG_NAME=<REPLACE_ME>

response=$(curl "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F" -H Metadata:true -s)
access_token=$(echo $response | python -c 'import sys, json; print (json.load(sys.stdin)["access_token"])')
echo "The managed identities for Azure resources access token is $access_token"

exp=$(date -u -d '+ 1 hour' "+%Y-%m-%dT%H:%M:%SZ")

echo "Retriving SAS token using MSI access token"
sas_response=$(curl https://management.azure.com/subscriptions/$SUB_ID/resourceGroups/$RG_NAME/providers/Microsoft.Storage/storageAccounts/$STORAGE_ACCOUNT/listServiceSas/?api-version=2017-06-01 -X POST -d "{\"canonicalizedResource\":\"/blob/$STORAGE_ACCOUNT/scripts\",\"signedResource\":\"c\",\"signedPermission\":\"rcw\",\"signedProtocol\":\"https\",\"signedExpiry\":\"$exp\"}" -H "Authorization: Bearer $access_token")
sas=$(echo $sas_response | python -c 'import sys, json; print (json.load(sys.stdin)["serviceSasToken"])')
echo "SAS Token: $sas"

echo "Curl blob: https://$STORAGE_ACCOUNT.blob.core.windows.net/scripts/custom-script-extension.sh?$sas" 
curl https://$STORAGE_ACCOUNT.blob.core.windows.net/scripts/custom-script-extension.sh?$sas 
```

To get out of your current SSH connection, run:
```bash
exit
```

## [LAB 4 - Configure VMSS Auto OS Image Upgrade](./4-auto-os-img.sh)

We previously created a VMSS with an specific image version. But, what about if you would like your image be automatically applied in your scale set when a new version is available in your Azure Compute Gallery or Azure Marketplace?

Note that Auto OS Image Upgrade require a **Health Check probe** to make sure the VM is Healthy before moving on to the next batch of server (20% at a time), so this script is also creating an HTTP health check. 

By default the Upgrade policy is set to Automatic. Once that we our Health Check and all our instances are updated, and to be able to control our updates in this demo, we will set it to Manual inside the provided script. 

If you are are using a Custom Image, make sure it points to a latest version and you update **4-auto-os-img.sh** variables accordingly. From:

```bash
source ./set-variables.sh
```
to 
```bash
source ./set-variables.sh -g "/subscriptions/<SUB_ID>/resourceGroups/<RG_NAME>/providers/Microsoft.Compute/galleries/<GALLERY_NAME>/images/IMG_DEF"
```
**Note there is no "/versions/X.X.X" at the end of the Image Resource Id.**

To configure VMSS Auto OS Upgrade run:
```bash
./4-auto-os-img.sh
```

## [LAB 5 - Create Recovery Services Vault and configure Virtual Machine Backup](./5-rsv.sh)

Our current demo architecture has a single point of failure, the Virtual Machine, in case of disaster there are still ways to recover. 

Recovery Services Vault, will allow us to create VM Backups that will allow you to either recover the entire VM or files.

To Create and configure Azure Backup, run:
```bash
./5-rsv.sh
```

## LAB 6 - Configure Azure DevOps Pipelines and provision with Terraform

This lab will use files under **pipelines** and **terraform** folder. 

* Create a new Azure Service Connection to your Azure Subscription, for more information see [here](https://docs.microsoft.com/en-us/azure/devops/pipelines/library/service-endpoints)
    * Connection type: **Azure Resource Manager**.
    * Authentication Method: **Service Principal (automatic)** - this option will automatically create the Service Principal on your behalf, if you don't have permissions to create a Service Principal please use the manual option. 
    * Scope level: Select the appropiate level, for this project I used **Subscription**.
    * Service connection name: **my-ado-azure-subscription-service-connection**.
    
    **Note: The Service connection name can be customized, just remember to update all azure-pipelines.yml files to use the right Service Connection name in the variables section.**

* To import this repository into your Azure Repos, follow [Import Git Repository documentation](https://docs.microsoft.com/en-us/azure/devops/repos/git/import-git-repository?view=azure-devops)
    * Git repo URL: https://github.com/aleguillen/azure-iaas.git

* Create a new Azure Pipeline to deploy your resouces
    * Sign-in to your Azure DevOps organization and go to your project.
    * Go to **Pipelines**, and then select **New pipeline**.
    * Do the steps of the wizard by first selecting **Azure Repos Git** as the location of your source code.
    * When you see the list of repositories, **select your repository**.
    * Under Configura your pipeline, select **Existing Azure Pipelines YAML file** and select the file **/pipelines/azure-pipelines.yml** from the dropdown.
    * Click **Continue** and **Run** your pipeline.


Check in the portal for the new VM. And in the Cloud Shell console you can run these commands, to ensure Cloud-init ran correctly from the pipeline as well:

```bash
source ./set-variables.sh

INSTANCE_ID=$(az vmss list-instances \
  --resource-group $RG_NAME \
  --name $TF_VMSS_NAME \
  --output tsv --query [0].instanceId)

echo "Testing using Run-Command Welcome page in NGINX - From Terraform VMSS"
az vmss run-command invoke \
  --resource-group $RG_NAME \
  --name $TF_VMSS_NAME \
  --instance-id $INSTANCE_ID \
  --command-id RunShellScript \
  --scripts "curl localhost" 
```

## [Clean-up Resources](./rg-clean-up.sh)

To remove all resources in your Resource Group, to avoid unnecessary charges, run:

```bash
./rg-clean-up.sh
```