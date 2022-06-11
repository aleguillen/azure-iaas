###
### PRIVATE LINK AND SSH CONNECTIVITY
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "my-image-resource-id" 

echo "Setting Auto Scaling for VMSS"
