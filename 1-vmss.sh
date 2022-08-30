###
### VMSS WITH CUSTOM SCRIPT EXTENSION
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "/subscriptions/SUB_ID/resourceGroups/RG_NAME/providers/Microsoft.Compute/galleries/GALLERY_NAME/images/IMG_DEF/versions/1.0.0"

if [[ -n "$GOLDEN_IMAGE" ]]
then
  echo "IMAGE FOUND: $GOLDEN_IMAGE"
  IMAGE=$GOLDEN_IMAGE

else
  echo "NO CUSTOM IMAGE SPECIFIED: Using UbuntuLTS Azure Marketplace Image"
  IMAGE="UbuntuLTS"
fi 

if [[ "${PUBLIC_RESOURCES,,}" == "true" ]]
then
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
      --authentication-type ssh \
      --nics "$VM_NAME-nic" \
      --generate-ssh-keys

  az network nic ip-config address-pool add \
    --address-pool myBackEndPool \
    --ip-config-name ipconfig1 \
    --nic-name "$VM_NAME-nic" \
    --resource-group $RG_NAME \
    --lb-name "public-lb"

  # Enable Boot Diagnostics for VM
  az vm boot-diagnostics enable \
    --name $VM_NAME \
    --resource-group $RG_NAME \
    --storage "https://$STORAGE_ACCOUNT.blob.core.windows.net"

    
  echo "Adding CustomScript Extension to configure NGINX inside the VM"
  az vm extension set \
    -n CustomScript \
    --publisher Microsoft.Azure.Extensions \
    --version 2.0 \
    --vm-name $VM_NAME \
    --resource-group $RG_NAME \
    --settings '{"fileUris":["https://raw.githubusercontent.com/aleguillen/azure-iaas/main/custom-script-extension.sh"],"commandToExecute":"./custom-script-extension.sh"}'
    
  echo "Testing using Run-Command Welcome page in NGINX - From VM"
  az vm run-command invoke \
    -g $RG_NAME \
    -n $VM_NAME \
    --command-id RunShellScript \
    --scripts "curl localhost"
    
else 
  echo "NO PUBLIC VM NEEDED"
fi 


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
    --generate-ssh-keys \
    --custom-data "cloud-init.sh"

# Enable Boot Diagnostics for VMSS
az vmss update \
  --name $VMSS_NAME \
  --resource-group $RG_NAME \
  --set virtualMachineProfile.diagnosticsProfile.bootDiagnostics.enabled=True virtualMachineProfile.diagnosticsProfile.bootDiagnostics.storageUri="https://$STORAGE_ACCOUNT.blob.core.windows.net"

az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output table --query '[].{InstanceId: instanceId, Name: name, ComputerName: osProfile.computerName, AvailabilityZone: zones[0], LatestModelApplied: latestModelApplied, ImageVersion: storageProfile.imageReference.exactVersion}'

INSTANCE_ID=$(az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output tsv --query [0].instanceId)

echo "Testing using Run-Command Welcome page in NGINX - From VMSS"
az vmss run-command invoke \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --instance-id $INSTANCE_ID \
  --command-id RunShellScript \
  --scripts "curl localhost" 