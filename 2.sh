# USE GLOBAL VARIABLES
#source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
source ./set-variables.sh -g "/subscriptions/5202ea18-a138-47f1-a47a-0a24613a45f4/resourceGroups/rg-algut-images/providers/Microsoft.Compute/galleries/imagesalgut/images/Ubuntu-16.04-LTS/versions/1.0.0" 

if [[ -n "$GOLDEN_IMAGE" ]]
then
  echo "IMAGE FOUND: $GOLDEN_IMAGE"
  IMAGE=$GOLDEN_IMAGE

else
  echo "NO CUSTOM IMAGE SPECIFIED: Using UbuntuLTS Azure Marketplace Image"
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

az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output table

echo "Adding CustomScript Extension to configure NGINX "
az vmss extension set \
  --publisher Microsoft.Azure.Extensions \
  --version 2.0 \
  --name CustomScript \
  --resource-group $RG_NAME \
  --vmss-name $VMSS_NAME \
  --settings '{"fileUris":["https://raw.githubusercontent.com/aleguillen/azure-iaas/main/custom-script-extension.sh"],"commandToExecute":"./custom-script-extension.sh"}'
