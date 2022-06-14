###
### SET VMSS AUTO-SCALING AND SCALE-IN POLICY
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "my-image-resource-id" 

echo "Define an autoscale profile"
az monitor autoscale create \
  --resource-group $RG_NAME \
  --resource $VMSS_NAME \
  --resource-type "Microsoft.Compute/virtualMachineScaleSets" \
  --name "$VMSS_NAME-autoscale" \
  --min-count 1 \
  --max-count 3 \
  --count 1

echo "Create Auto-Scaling Rule based on Storage Queue Message Count."
echo "IF MessageCount > 3 or CPU > 75%, then SCALE OUT by 1."
STORAGE_ID=$(az storage account show --name $RG_NAME --name $STORAGE_ACCOUNT --query id -o tsv)

az monitor autoscale rule create \
  --resource-group $RG_NAME \
  --autoscale-name "$VMSS_NAME-autoscale" \
  --condition "Percentage CPU > 75 avg 5m" \
  --scale out 1 \
  --cooldown 10 

az monitor autoscale rule create \
  --autoscale-name "$VMSS_NAME-autoscale" \
  --resource-group $RG_NAME \
  --condition "ApproximateMessageCount > 3 avg 5m" \
  --scale out 1 \
  --cooldown 10 \
  --resource "${STORAGE_ID}/services/queue/queues/wsqueue" 

echo "IF MessageCount < 1 or CPU < 25%, then SCALE IN by 1."

az monitor autoscale rule create \
  --resource-group $RG_NAME \
  --autoscale-name "$VMSS_NAME-autoscale" \
  --condition "Percentage CPU < 25 avg 5m" \
  --scale in 1 \
  --cooldown 10 

az monitor autoscale rule create \
  --autoscale-name "$VMSS_NAME-autoscale" \
  --resource-group $RG_NAME \
  --condition "ApproximateMessageCount < 1 avg 5m" \
  --scale in 1 \
  --cooldown 10 \
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

## Clear Storage Account Queue to force VMSS to scale down
#az storage message clear -q wsqueue --account-name $STORAGE_ACCOUNT