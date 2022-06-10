# USE GLOBAL VARIABLES
source ./set-variables.sh   # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"

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

az vmss get-instance-view \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --instance-id 1