###
### SET VMSS AUTO-SCALING AND SCALE-IN POLICY
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "/subscriptions/SUB_ID/resourceGroups/RG_NAME/providers/Microsoft.Compute/galleries/GALLERY_NAME/images/IMG_DEF/versions/1.0.0"

echo "Current Instances in Scale Set before Scaling"
az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output table --query '[].{InstanceId: instanceId, Name: name, ComputerName: osProfile.computerName, AvailabilityZone: zones[0], LatestModelApplied: latestModelApplied, ImageVersion: storageProfile.imageReference.exactVersion}'

echo "Define an autoscale profile"
az monitor autoscale create \
  --resource-group $RG_NAME \
  --resource $VMSS_NAME \
  --resource-type "Microsoft.Compute/virtualMachineScaleSets" \
  --name "$VMSS_NAME-autoscale" \
  --min-count 1 \
  --max-count 3 \
  --count 2

echo "Create Auto-Scaling Rule based on Storage Queue Message Count."
echo "IF MessageCount > 3, then SCALE OUT by 1."
STORAGE_ID=$(az storage account show --name $RG_NAME --name $STORAGE_ACCOUNT --query id -o tsv)

az monitor autoscale rule create \
  --autoscale-name "$VMSS_NAME-autoscale" \
  --resource-group $RG_NAME \
  --condition "ApproximateMessageCount > 3 avg 1m" \
  --scale out 1 \
  --cooldown 1 \
  --resource "${STORAGE_ID}/services/queue/queues/wsqueue" 

echo "IF MessageCount < 1, then SCALE IN by 1."

az monitor autoscale rule create \
  --autoscale-name "$VMSS_NAME-autoscale" \
  --resource-group $RG_NAME \
  --condition "ApproximateMessageCount < 1 avg 1m" \
  --scale in 1 \
  --cooldown 1 \
  --resource "${STORAGE_ID}/services/queue/queues/wsqueue" 


echo "Adding Message to Queue to test AutoScaling:"

array=(1 2 3 4)
for index in "${array[@]}"
do
  az storage message put \
    --content "Test AutoScaling Message $index" \
    --queue-name wsqueue \
    --account-name $STORAGE_ACCOUNT
done

echo "Waiting 30 seconds"
sleep 30 

echo "Current Instances in Scale Set when Scaling"
az vmss list-instances \
  --resource-group $RG_NAME \
  --name $VMSS_NAME \
  --output table --query '[].{InstanceId: instanceId, Name: name, ComputerName: osProfile.computerName, AvailabilityZone: zones[0], LatestModelApplied: latestModelApplied, ImageVersion: storageProfile.imageReference.exactVersion}'

## Clear Storage Account Queue to force VMSS to scale down
#az storage message clear -q wsqueue --account-name $STORAGE_ACCOUNT