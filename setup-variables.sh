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
RG_NAME="$DEPLOYMENT_NAME-$LOCATION-rg-$INDEX"
echo " - RG_NAME = " $RG_NAME

VNET_NAME="$DEPLOYMENT_NAME-$LOCATION-vnet-$INDEX"
echo " - VNET_NAME = " $VNET_NAME

NSG_NAME="$DEPLOYMENT_NAME-$LOCATION-nsg-$INDEX"
echo " - NSG_NAME = " $NSG_NAME

VM_NAME="$DEPLOYMENT_NAME-$LOCATION-vm-$INDEX"
echo " - VM_NAME = " $VM_NAME

VMSS_NAME="$DEPLOYMENT_NAME-$LOCATION-vmss-$INDEX"
echo " - VMSS_NAME = " $VMSS_NAME