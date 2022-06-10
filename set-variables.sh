## THIS FILE CONTAINS ALL WORKSHOP VARIABLES
# Default Values
DEPLOYMENT_NAME="workshop"
LOCATION="eastus2"
INDEX="01"
GOLDEN_IMAGE=""

echo "INPUT VARIABLES:"
while getopts d:l:i:img: flag
do
    case "${flag}" in
        d) 
            FLAG_NAME=DEPLOYMENT_NAME
            DEPLOYMENT_NAME=${OPTARG};;
        l) 
            FLAG_NAME=LOCATION
            LOCATION=${OPTARG};;
        i) 
            FLAG_NAME=INDEX
            INDEX=${OPTARG};;
        g) 
            FLAG_NAME=GOLDEN_IMAGE
            GOLDEN_IMAGE=${OPTARG};;
    esac
    echo " - "$FLAG_NAME " = " ${OPTARG}
done

echo "GENERATING VARIABLES:"
RG_NAME="$DEPLOYMENT_NAME-$LOCATION-rg"
echo " - RG_NAME = " $RG_NAME

VNET_NAME="$DEPLOYMENT_NAME-$LOCATION-vnet"
echo " - VNET_NAME = " $VNET_NAME

NSG_NAME="$DEPLOYMENT_NAME-$LOCATION-nsg"
echo " - NSG_NAME = " $NSG_NAME

KV_NAME="$DEPLOYMENT_NAME-$LOCATION-kv"
echo " - KV_NAME = " $KV_NAME


VM_NAME="$DEPLOYMENT_NAME-$LOCATION-vm-$INDEX"
echo " - VM_NAME = " $VM_NAME

VMSS_NAME="$DEPLOYMENT_NAME-$LOCATION-vmss-$INDEX"
echo " - VMSS_NAME = " $VMSS_NAME
