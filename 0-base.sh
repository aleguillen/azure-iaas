###
### BASE INFRASTRUCTURE
###

# USE GLOBAL VARIABLES
source ./set-variables.sh   # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"

echo "Current Azure Subscription:"
az account show

echo "Creating Resource Group:"
az group create --location $LOCATION --name $RG_NAME

echo "Creating Virtual Networks:"
az network vnet create \
    --resource-group $RG_NAME \
    --location $LOCATION \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/16 \
    --subnet-name "public-snet" \
    --subnet-prefixes 10.0.0.0/24

az network vnet create \
    --resource-group $RG_NAME \
    --location $LOCATION \
    --name $VNET2_NAME \
    --address-prefixes 10.1.0.0/16 \
    --subnet-name "private-snet" \
    --subnet-prefixes 10.1.0.0/24

az network vnet subnet update \
    -n "public-snet" \
    --vnet-name $VNET_NAME \
    -g $RG_NAME \
    --disable-private-link-service-network-policies true \
    --disable-private-endpoint-network-policies true

    
az network vnet subnet update \
    -n "private-snet" \
    --vnet-name $VNET2_NAME \
    -g $RG_NAME \
    --disable-private-link-service-network-policies true \
    --disable-private-endpoint-network-policies true

echo "Creating NSGs for Subnets Security"
az network nsg create \
    --resource-group $RG_NAME \
    --name $NSG_NAME
    
az network nsg create \
    --resource-group $RG_NAME \
    --name $NSG2_NAME

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

az network vnet subnet update -g $RG_NAME -n "public-snet" --vnet-name $VNET_NAME --network-security-group $NSG_NAME
az network vnet subnet update -g $RG_NAME -n "private-snet" --vnet-name $VNET2_NAME --network-security-group $NSG2_NAME

echo "Creating Internal Load Balancer (LB)"
az network lb create \
    --resource-group $RG_NAME \
    --name "internal-lb" \
    --sku Standard \
    --vnet-name $VNET2_NAME \
    --subnet "private-snet" \
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
    --public-ip-address "public-ip" \
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

echo "Setup NAT Gateway for outbound connections for VMSS"
az network public-ip create \
    --resource-group $RG_NAME \
    --name "nat-gw-public-ip" \
    --sku Standard

az network nat gateway create \
    --resource-group $RG_NAME \
    --name "natGateway" \
    --public-ip-addresses "nat-gw-public-ip" \
    --idle-timeout 10

az network vnet subnet update \
    --resource-group $RG_NAME \
    --vnet-name $VNET2_NAME \
    --name "private-snet" \
    --nat-gateway "natGateway"


echo "Creating Azure Key Vault:"
az keyvault create \
    --resource-group $RG_NAME \
    --location $LOCATION \
    --name $KV_NAME \
    --enable-rbac-authorization true 

KV_ID=$(az keyvault show --name $RG_NAME --name $KV_NAME --query id -o tsv)
USER_OID=$(az ad signed-in-user show --query id -o tsv) 
az role assignment create \
    --role "Key Vault Administrator" \
    --assignee $USER_OID \
    --scope $KV_ID

echo "Creating Storage Account"
az storage account create \
    -n $STORAGE_ACCOUNT \
    -g $RG_NAME \
    -l $LOCATION \
    --sku Standard_LRS

STORAGE_ID=$(az storage account show --name $RG_NAME --name $STORAGE_ACCOUNT --query id -o tsv)
USER_OID=$(az ad signed-in-user show --query id -o tsv) 
az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee $USER_OID \
    --scope $STORAGE_ID

echo "Creating Queue"
az storage queue create \
    -n wsqueue \
    --account-name $STORAGE_ACCOUNT

echo "Creating Storage Account Blob Container:"
az storage container create \
    --account-name $STORAGE_ACCOUNT \
    --name scripts 

az storage blob upload \
    --account-name $STORAGE_ACCOUNT \
    -f "./custom-script-extension.sh" \
    -c scripts \
    -n "custom-script-extension.sh"
