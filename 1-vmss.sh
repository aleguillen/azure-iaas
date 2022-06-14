###
### VMSS WITH CUSTOM SCRIPT EXTENSION
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "my-image-resource-id" 

if [[ -n "$GOLDEN_IMAGE" ]]
then
  echo "IMAGE FOUND: $GOLDEN_IMAGE"
  IMAGE=$GOLDEN_IMAGE

else
  echo "NO CUSTOM IMAGE SPECIFIED: Using UbuntuLTS Azure Marketplace Image"
  IMAGE="UbuntuLTS"
fi 

echo "Creating a Public VM - admin user: azureuser (SSH keys generated)"

az network nic create \
        --resource-group $RG_NAME \
        --name "$VM_NAME-nic" \
        --vnet-name $VNET_NAME \
        --subnet "public-snet" 

az vm create \
    --resource-group $RG_NAME \
    --name $VM_NAME \
    --image $IMAGE \
    --admin-username azureuser \
    --assign-identity \
    --authentication-type all \
    --nics "$VM_NAME-nic" \
    --generate-ssh-keys

az network nic ip-config address-pool add \
   --address-pool myBackEndPool \
   --ip-config-name ipconfig1 \
   --nic-name "$VM_NAME-nic" \
   --resource-group $RG_NAME \
   --lb-name "public-lb"

echo "Creating a Private VMSS - admin user: azureuser (SSH keys generated)"
az vmss create \
    --resource-group $RG_NAME \
    --name $VMSS_NAME \
    --image $IMAGE \
    --upgrade-policy-mode automatic \
    --admin-username azureuser \
    --admin-password $VMSS_PASS \
    --assign-identity \
    --authentication-type all \
    --computer-name-prefix $VMSS_NAME \
    --load-balancer "internal-lb" \
    --vnet-name $VNET2_NAME \
    --subnet "private-snet" \
    --zones 1 2 3 \
    --generate-ssh-keys

az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output table

echo "Adding CustomScript Extension to configure NGINX."
az vm extension set \
  -n CustomScript \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --vm-name $VM_NAME \
  --resource-group $RG_NAME \
  --settings '{"fileUris":["https://raw.githubusercontent.com/aleguillen/azure-iaas/main/custom-script-extension.sh"],"commandToExecute":"./custom-script-extension.sh"}'
  