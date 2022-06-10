# USE GLOBAL VARIABLES
sh ./set-variables.sh   # CHANGE DEFAULTS USING: sh ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"

echo "Current Azure Subscription:"
az account show

echo "Creating Resource Group:"
az group create --location $LOCATION --name $RG_NAME

echo "Creating Virtual Network:"
az network vnet create \
    --resource-group $RG_NAME \
    --location $LOCATIONC \
    --name $VNET_NAME \
    --address-prefixes 10.0.0.0/16 \
    --subnet-name lb-snet \
    --subnet-prefixes 10.0.0.0/24

az network vnet subnet create \
    --name pe-snet \
    --resource-group $RG_NAME \
    --vnet-name $VNET_NAME \
    --address-prefixes 10.0.1.0/24 \
    --disable-private-link-service-network-policies true \
    --disable-pro

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

if [[ -n "$VM_IMAGE" ]]
then
  echo "IMAGE FOUND: $GOLDEN_IMAGE"
  IMAGE=$GOLDEN_IMAGE

else
  echo "NO CUSTOM IMAGE SPECIFIED"
  IMAGE="UbuntuLTS"
fi 

echo "Creating VMSS - admin user: azureuser (SSH keys generated)"
az vmss create \
    --resource-group $RG_NAME \
    --name $VMSS_NAME \
    --image $IMAGE \
    --upgrade-policy-mode automatic \
    --admin-username azureuser \
    --generate-ssh-keys