sh ./setup-variables.sh

echo "Current Azure Subscription:"
az account show

echo "Creating Resource Group:"
az group create --location $LOCATION --name $RG_NAME

echo "Creating Virtual Network:"
az 

if [[ -n "$VM_IMAGE" ]]
then
  echo "not Empty"
else
  echo "NO CUSTOM IMAGE SPECIFIED"
  az vm create \
    --resource-group myResourceGroup \
    --name myVM \
    --image Debian \
    --admin-username azureuser \
    --generate-ssh-keys
fi 

