###
### CREATE RECOVERY SERVICES VAULT AND CONFIGURE BACKUP
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "/subscriptions/SUB_ID/resourceGroups/RG_NAME/providers/Microsoft.Compute/galleries/GALLERY_NAME/images/IMG_DEF/versions/1.0.0"

echo "Create Recovery Services Vault"
az backup vault create \
    --resource-group $RG_NAME \
    --name $RSV_NAME \
    --location $LOCATION

echo "Enable Backup for VM"
az backup protection enable-for-vm \
    --resource-group $RG_NAME \
    --vault-name $RSV_NAME \
    --vm $VM_NAME \
    --policy-name DefaultPolicy

echo "Start initial backup job"
az backup protection backup-now \
    --resource-group $RG_NAME \
    --vault-name $RSV_NAME \
    --container-name $VM_NAME \
    --item-name $VM_NAMEmyVM \
    --backup-management-type AzureIaaSVM

echo "List all Backup Jobs: "
az backup job list \
    --resource-group $RG_NAME \
    --vault-name $RSV_NAME \
    --output table