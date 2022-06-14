###
### PRIVATE LINK AND SSH CONNECTIVITY
###

# USE GLOBAL VARIABLES
source ./set-variables.sh  # CHANGE DEFAULTS USING: source ./set-variables.sh -d poc -l southcentralus -i 1 -g "myimageid"
#source ./set-variables.sh -g "my-image-resource-id" 

echo "Creating Private Endpoint to Storage Account:"

STORAGE_ID=$(az storage account show --resource-group $RG_NAME --name $STORAGE_ACCOUNT --query id -o tsv)

az network private-endpoint create \
    --connection-name "$STORAGE_ACCOUNT-connection" \
    --name "$STORAGE_ACCOUNT-pe" \
    --private-connection-resource-id $STORAGE_ID \
    --resource-group $RG_NAME \
    --subnet "private-snet" \
    --group-id blob \
    --vnet-name $VNET2_NAME

echo "Creating Private DNS Zone for Storage Account and link DNS zone to VNET:"
az network private-dns zone create \
    --resource-group $RG_NAME \
    --name "privatelink.blob.core.windows.net"

az network private-dns link vnet create \
    --resource-group $RG_NAME \
    --zone-name "privatelink.blob.core.windows.net" \
    --name MyDNSLink \
    --virtual-network $VNET2_NAME \
    --registration-enabled false

az network private-endpoint dns-zone-group create \
    --resource-group $RG_NAME \
    --endpoint-name "$STORAGE_ACCOUNT-pe" \
    --name DNSZoneGroup \
    --private-dns-zone "privatelink.blob.core.windows.net" \
    --zone-name blob

echo "Creating Private Endpoint to Key Vault:"
KV_ID=$(az keyvault show --resource-group $RG_NAME --name $KV_NAME --query id -o tsv)

az network private-endpoint create \
    --connection-name "$KV_NAME-connection" \
    --name "$KV_NAME-pe" \
    --private-connection-resource-id $KV_ID \
    --resource-group $RG_NAME \
    --subnet "private-snet" \
    --group-id vault \
    --vnet-name $VNET2_NAME

echo "Creating Private DNS Zone for Key Vault and link DNS zone to VNET:"
az network private-dns zone create \
    --resource-group $RG_NAME \
    --name "privatelink.vaultcore.azure.net"

az network private-dns link vnet create \
    --resource-group $RG_NAME \
    --zone-name "privatelink.vaultcore.azure.net" \
    --name MyDNSLink \
    --virtual-network $VNET2_NAME \
    --registration-enabled false

az network private-endpoint dns-zone-group create \
    --resource-group $RG_NAME \
    --endpoint-name "$KV_NAME-pe" \
    --name DNSZoneGroup \
    --private-dns-zone "privatelink.vaultcore.azure.net" \
    --zone-name vault

echo "Creating Private Link Service to VMMS"
az network private-link-service create \
    --resource-group $RG_NAME \
    --name "$VMSS_NAME-pls" \
    --vnet-name $VNET2_NAME \
    --subnet "private-snet" \
    --lb-name "internal-lb" \
    --lb-frontend-ip-configs myFrontEnd \
    --location $LOCATION

echo "Create Private Endpoint from VNET-01 to connect to VMSS in VNET-02 via private endpoint"

PLS_ID=$(az network private-link-service show \
    --name "$VMSS_NAME-pls" \
    --resource-group $RG_NAME \
    --query id \
    --output tsv)

az network private-endpoint create \
    --connection-name "$VMSS_NAME-pls-connection" \
    --name "$VMSS_NAME-pls-pe" \
    --private-connection-resource-id $PLS_ID \
    --resource-group $RG_NAME \
    --subnet "public-snet" \
    --manual-request false \
    --vnet-name $VNET_NAME

echo "Create NSG rule and LB rule to allow port 22 into your VM"

az network lb rule create \
    --resource-group $RG_NAME \
    --lb-name "public-lb" \
    --name SSHPLBrule \
    --protocol tcp \
    --frontend-port 22 \
    --backend-port 22 \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool \
    --probe-name HTTPHealthProbe \
    --idle-timeout 15 \
    --enable-tcp-reset true

az network nsg rule create \
    --resource-group $RG_NAME \
    --nsg-name $NSG_NAME \
    --name SSHAllowRule \
    --protocol '*' \
    --direction inbound \
    --source-address-prefix '*' \
    --source-port-range '*' \
    --destination-address-prefix '*' \
    --destination-port-range 22 \
    --access allow \
    --priority 300

az network lb rule create \
    --resource-group $RG_NAME \
    --lb-name "internal-lb" \
    --name SSHPLBrule \
    --protocol tcp \
    --frontend-port 22 \
    --backend-port 22 \
    --frontend-ip-name myFrontEnd \
    --backend-pool-name myBackEndPool \
    --probe-name HTTPHealthProbe \
    --idle-timeout 15 \
    --enable-tcp-reset true

PE_NIC_ID=$(az network private-endpoint show --name "$VMSS_NAME-pls-pe" --resource-group $RG_NAME --query networkInterfaces[0].id -o tsv)
PE_IP_ADDRESS=$(az network nic show --ids $PE_NIC_ID --query ipConfigurations[0].privateIpAddress -o tsv)

PUBLIC_IP=$(az network public-ip show --resource-group $RG_NAME --name "public-ip" --query ipAddress -o tsv)

echo "Setting Storage Blob RBAC to grant Contributor acccess for VMSS:"
STORAGE_ID=$(az storage account show --name $RG_NAME --name $STORAGE_ACCOUNT --query id -o tsv)
VMSS_MSI=$(az vmss show --resource-group $RG_NAME --name $VMSS_NAME --query identity.principalId -o tsv)
az role assignment create \
    --role "Contributor" \
    --assignee $VMSS_MSI \
    --scope $STORAGE_ID

echo "To SSH to the Jump Public Server execute:"
echo "ssh azureuser@$PUBLIC_IP"
echo "Then SSH to the VMSS, your password is $VMSS_PASS : "
echo "ssh azureuser@$PE_IP_ADDRESS"

