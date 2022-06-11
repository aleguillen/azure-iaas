###
### BASE INFRASTRUCTURE
###

# USE GLOBAL VARIABLES
source ./set-variables.sh   # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"

echo "Current Azure Subscription:"
az account show

echo "Creating Resource Group:"
az group create --location $LOCATION --name $RG_NAME

echo "Creating Virtual Network:"
az network vnet create \
    --resource-group $RG_NAME \
    --location $LOCATION \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/16 \
    --subnet-name lb-snet \
    --subnet-prefixes 10.0.0.0/24

az network vnet subnet create \
    --name pe-snet \
    --resource-group $RG_NAME \
    --vnet-name $VNET_NAME \
    --address-prefixes 10.0.1.0/24 \
    --disable-private-link-service-network-policies true 

echo "Creating NSG for Subnets Security"
az network nsg create \
    --resource-group $RG_NAME \
    --name $NSG_NAME

echo "For Demo purposes - Create HTTP Allow rule from internet"
az network nsg rule create \
    --resource-group $RG_NAME \
    --nsg-name $NSG_NAME \
    --name HTTPAllowRule \
    --protocol '*' \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 80 \
    --access allow \
    --priority 200

echo "Creating Internal Load Balancer (LB)"
az network lb create \
    --resource-group $RG_NAME \
    --name "internal-lb" \
    --sku Standard \
    --vnet-name $VNET_NAME \
    --subnet lb-snet \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool

az network lb probe create \
    --resource-group $RG_NAME \
    --lb-name "internal-lb" \
    --name HTTPHealthProbe \
    --protocol tcp \
    --port 80

az network lb rule create \
    --resource-group $RG_NAME \
    --lb-name "internal-lb" \
    --name HTTPLBrule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool \
    --probe-name HTTPHealthProbe \
    --idle-timeout 15 \
    --enable-tcp-reset true

echo "Creating Public Load Balancer:"
az network public-ip create \
    --resource-group $RG_NAME \
    --name "public-ip" \
    --sku Standard

az network lb create \
    --resource-group $RG_NAME \
    --name "public-lb" \
    --sku Standard \
    --public-ip-address public-ip \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool

az network lb probe create \
    --resource-group $RG_NAME \
    --lb-name "public-lb" \
    --name HTTPHealthProbe \
    --protocol tcp \
    --port 80

az network lb rule create \
    --resource-group $RG_NAME \
    --lb-name "public-lb" \
    --name HTTPAllowRule \
    --protocol tcp \
    --frontend-port 80 \
    --backend-port 80 \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool \
    --probe-name HTTPHealthProbe \
    --idle-timeout 15 \
    --enable-tcp-reset true

echo "Creating Azure Key Vault"
az keyvault create \
    --resource-group $RG_NAME
    --location $LOCATION \
    --name $KV_NAME 

echo "Creating Storage Account"
RG_ID=$(az group show --name $RG_NAME --query id)
UNIQUE_STRING=$(echo $RG_ID | md5sum | head -c 5)
STORAGE_ACCOUNT=${DEPLOYMENT_NAME}${UNIQUE_STRING}sa
az storage account create \
    -n $STORAGE_ACCOUNT \
    -g $RG_NAME \
    -l $LOCATION \
    --sku Standard_LRS

STORAGE_ID=$(az storage account show --name $RG_NAME --name $STORAGE_ACCOUNT --query id)
USER_OID=$(az ad signed-in-user show --query id -o tsv) 
az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee $USER_OID \
    --scope $STORAGE_ID


az storage container create \
    --account-name $STORAGE_ACCOUNT \
    --name scripts 

az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    -f "./custom-script-extension.sh" \
    -c scripts \
    -n "custom-script-extension.sh"