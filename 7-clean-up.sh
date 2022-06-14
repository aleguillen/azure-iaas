###
### CLEAN UP RESOURCES
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "my-image-resource-id" 

echo "Remove the resource group and all resources associated"
az group delete --name $RG_NAME