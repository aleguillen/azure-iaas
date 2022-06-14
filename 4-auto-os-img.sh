###
### VMSS AUTO OS IMAGE UPGRADE
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "my-image-resource-id" 

echo "Setting Auto Scaling for VMSS"
az vmss update \
    --name MyScaleSet \
    --resource-group MyResourceGroup \
    --set virtualMachineProfile.storageProfile.imageReference.id=imageID

az vmss update [--add]
               [--automatic-repairs-action {Reimage, Replace, Restart}]
               [--automatic-repairs-grace-period]
               [--capacity-reservation-group]
               [--enable-automatic-repairs {false, true}]
               [--enable-cross-zone-upgrade {false, true}]
               [--enable-secure-boot {false, true}]
               [--enable-spot-restore {false, true}]
               [--enable-terminate-notification {false, true}]
               [--enable-vtpm {false, true}]
               [--ephemeral-os-disk-placement {CacheDisk, ResourceDisk}]
               [--force-deletion]
               [--force-string]
               [--ids]
               [--instance-id]
               [--license-type {None, RHEL_BASE, RHEL_BASESAPAPPS, RHEL_BASESAPHA, RHEL_BYOS, RHEL_ELS_6, RHEL_EUS, RHEL_SAPAPPS, RHEL_SAPHA, SLES, SLES_BYOS, SLES_HPC, SLES_SAP, SLES_STANDARD, Windows_Client, Windows_Server}]
               [--max-batch-instance-percent]
               [--max-price]
               [--max-unhealthy-instance-percent]
               [--max-unhealthy-upgraded-instance-percent]
               [--name]
               [--no-wait]
               [--pause-time-between-batches]
               [--ppg]
               [--prioritize-unhealthy-instances {false, true}]
               [--priority {Low, Regular, Spot}]
               [--protect-from-scale-in {false, true}]
               [--protect-from-scale-set-actions {false, true}]
               [--remove]
               [--resource-group]
               [--scale-in-policy {Default, NewestVM, OldestVM}]
               [--set]
               [--spot-restore-timeout]
               [--terminate-notification-time]
               [--ultra-ssd-enabled {false, true}]
               [--user-data]
               [--v-cpus-available]
               [--v-cpus-per-core]
               [--vm-sku]