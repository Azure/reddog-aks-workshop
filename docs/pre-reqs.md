
```bash
az provider register --namespace Microsoft.Quota
az provider show -n Microsoft.Quota

LOCATION=eastus

# Core Quota Check
###################################
COMPUTE_FAMILY="standardDSv2Family"

CORE_QUOTA=$(az quota show --resource-name $COMPUTE_FAMILY --scope 
"subscriptions/$SUBSCRIPTION/providers/Microsoft.Compute/locations/$LOCATION" -o tsv --query properties.limit.value)
CORE_USAGE=$(az quota usage show --resource-name $COMPUTE_FAMILY --scope 
"subscriptions/$SUBSCRIPTION/providers/Microsoft.Compute/locations/$LOCATION" -o tsv --query properties.usages.Value)

echo $COMPUTE_FAMILY usage: $CORE_USAGE/$CORE_QUOTA
###################################

# Public IP Quota Check
###################################
PUBLIC_IP_QUOTA=$(az quota show --resource-name "StandardSkuPublicIpAddresses" --scope 
"subscriptions/$SUBSCRIPTION/providers/Microsoft.Network/locations/$LOCATION" -o tsv --query properties.limit.value)

PUBLIC_IP_USAGE=$(az quota usage show --resource-name "StandardSkuPublicIpAddresses" --scope 
"subscriptions/$SUBSCRIPTION/providers/Microsoft.Network/locations/$LOCATION" -o tsv --query properties.usages.Value)

echo Public IPs: $PUBLIC_IP_USAGE/$PUBLIC_IP_QUOTA
###################################
```
