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

SUB_ID=$(az account show --query id -o tsv)
echo " - SUB_ID = " $SUB_ID

RG_NAME="$DEPLOYMENT_NAME-$LOCATION-rg"
echo " - RG_NAME = " $RG_NAME

VNET_NAME="$DEPLOYMENT_NAME-$LOCATION-vnet-01"
echo " - VNET_NAME = " $VNET_NAME

VNET2_NAME="$DEPLOYMENT_NAME-$LOCATION-vnet-02"
echo " - VNET2_NAME = " $VNET2_NAME

NSG_NAME="$DEPLOYMENT_NAME-$LOCATION-public-nsg"
echo " - NSG_NAME = " $NSG_NAME

NSG2_NAME="$DEPLOYMENT_NAME-$LOCATION-private-nsg"
echo " - NSG2_NAME = " $NSG2_NAME

KV_NAME="$DEPLOYMENT_NAME-$LOCATION-kv-$INDEX"
echo " - KV_NAME = " $KV_NAME

VM_NAME="$DEPLOYMENT_NAME-$LOCATION-vm-$INDEX"
echo " - VM_NAME = " $VM_NAME

VMSS_NAME="$DEPLOYMENT_NAME-$LOCATION-vmss-$INDEX"
echo " - VMSS_NAME = " $VMSS_NAME

RSV_NAME="$DEPLOYMENT_NAME-$LOCATION-rsv"
echo " - RSV_NAME = " $RSV_NAME

UNIQUE_STRING=$(echo "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME" | md5sum | head -c 5)
STORAGE_ACCOUNT="${DEPLOYMENT_NAME}${UNIQUE_STRING}sa"
echo " - STORAGE_ACCOUNT = " $STORAGE_ACCOUNT

VMSS_PASS="VMSS_pass-$UNIQUE_STRING"
echo " - VMSS_PASS = " $VMSS_PASS
