###
### VMSS AUTO OS IMAGE UPGRADE
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "/subscriptions/SUB_ID/resourceGroups/RG_NAME/providers/Microsoft.Compute/galleries/GALLERY_NAME/images/IMG_DEF"

echo "Retrieving OS Upgrade History"
az vmss get-os-upgrade-history --resource-group $RG_NAME --name $VMSS_NAME

echo "Current Instances and Versions in the Scale Set before OS Upgrade"
az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output table --query '[].{InstanceId: instanceId, Name: name, ComputerName: osProfile.computerName, AvailabilityZone: zones[0], LatestModelApplied: latestModelApplied, ImageVersion: storageProfile.imageReference.exactVersion}'

echo "Setting Application Health Linux extension for Health Check"
az vmss extension set \
  --name ApplicationHealthLinux \
  --publisher Microsoft.ManagedServices \
  --version 1.0 \
  --resource-group $RG_NAME \
  --vmss-name $VMSS_NAME \
  --settings '{ "protocol": "http", "port": 80, "requestPath": "/"}'

sleep 10

echo "Setting Upgrade Policy to Manual to prevent Auto Upgrades"
az vmss update \
    --name $VMSS_NAME \
    --resource-group $RG_NAME \
    --set upgradePolicy.mode="Manual"
    
if [[ -n "$GOLDEN_IMAGE" ]]
then
echo "IMAGE FOUND: $GOLDEN_IMAGE. Updating Image Reference ID"
IMAGE=$GOLDEN_IMAGE
az vmss update \
  --name $VMSS_NAME \
  --resource-group $RG_NAME \
  --set virtualMachineProfile.storageProfile.imageReference.id="$IMAGE"
else
  echo "NO CUSTOM IMAGE SPECIFIED: Setting Default"
  IMAGE="UbuntuLTS"
fi 

echo "Enabling Auto OS Image upgrade for VMSS with "
az vmss update \
    --name $VMSS_NAME \
    --resource-group $RG_NAME \
    --set UpgradePolicy.AutomaticOSUpgradePolicy.EnableAutomaticOSUpgrade=true

echo "Manually starting Image Upgrade"
az vmss rolling-upgrade start --resource-group $RG_NAME --name $VMSS_NAME

echo "Retrieving OS Upgrade History"
az vmss get-os-upgrade-history --resource-group $RG_NAME --name $VMSS_NAME

echo "Current Instances and Versions in the Scale Set after OS Upgrade"
az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output table --query '[].{InstanceId: instanceId, Name: name, ComputerName: osProfile.computerName, AvailabilityZone: zones[0], LatestModelApplied: latestModelApplied, ImageVersion: storageProfile.imageReference.exactVersion}'
