###
### CLEAN UP RESOURCES
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  

echo "Remove the resource group and all resources under $RG_NAME"
az group delete --name $RG_NAME