###
### CLEAN UP RESOURCES
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  

echo "Remove the resource group and all resources associated"
az group delete --name $RG_NAME