#!/bin/sh
## THIS FILE CONTAINS ALL WORKSHOP VARIABLES

# Default Values
DEPLOYMENT_NAME="workshop"
LOCATION="eastus2"
INDEX="01"
GOLDEN_IMAGE=""
PUBLIC_RESOURCES=true
DEPLOY_NATGW=true

#usage() { echo "Usage: $0 [-d <string>] [-l <string>] [-i <string>] [-g <string>] [-p <bool>] [-n <bool>]" 1>&2; exit 1; }

usage()
{
cat << EOF
Usage: $0 [-d <string>] [-l <string>] [-i <string>] [-g <string>] [-p <boolean>] [-n <boolean>]

OPTIONS:
   -d      Deployment Name Prefix for all Resources. Default = workshop
   -l      Azure Region. Default = eastus2
   -i      Index for naming convention for resouces. Default = 01
   -g      Golden Image for your IaaS resources. Default = Empty
   -p      If set to true script will provision all public resources. Default = true
   -n      If set to true script will provision NAT Gateway for Outbound Connectivity. Default = true
EOF
}

echo "INPUT VARIABLES:"
while getopts d:l:i:g:p:n:*: flag
do
    case "${flag}" in
        d) 
            FLAG_NAME=DEPLOYMENT_NAME
            DEPLOYMENT_NAME=${OPTARG};;
        l) 
            FLAG_NAME=LOCATION
            LOCATION=${OPTARG}
            ;;
        i) 
            FLAG_NAME=INDEX
            INDEX=${OPTARG}
            ;;
        g) 
            FLAG_NAME=GOLDEN_IMAGE
            GOLDEN_IMAGE=${OPTARG}
            ;;
        p) 
            FLAG_NAME=PUBLIC_RESOURCES
            PUBLIC_RESOURCES=${OPTARG}
            ;;
        n) 
            FLAG_NAME=DEPLOY_NATGW
            DEPLOY_NATGW=${OPTARG}
            ;;
        *) 
            echo "***************************"
            echo "* Invalid argument:"
            echo "***************************"
            usage
            exit 1
    esac
    
    echo " - "$FLAG_NAME"="${OPTARG}
    shift $((OPTIND-1))
done

echo "GENERATED VARIABLES:"

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

TF_VMSS_NAME="$DEPLOYMENT_NAME-$LOCATION-tf-vmss"
echo " - TF_VMSS_NAME = " $TF_VMSS_NAME

RSV_NAME="$DEPLOYMENT_NAME-$LOCATION-rsv"
echo " - RSV_NAME = " $RSV_NAME

UNIQUE_STRING=$(echo "/subscriptions/$SUB_ID/resourceGroups/$RG_NAME" | md5sum | head -c 5)
STORAGE_ACCOUNT="${DEPLOYMENT_NAME}${UNIQUE_STRING}sa"
echo " - STORAGE_ACCOUNT = " $STORAGE_ACCOUNT

VMSS_PASS="VMSS_pass-$UNIQUE_STRING"
echo " - VMSS_PASS = " $VMSS_PASS
