# Cheat Sheet

## Environment Planning

```bash
# Resource Group Creation
RG=RedDogAKSWorkshop
LOC=eastus
az group create -g $RG -l $LOC

# Get the resource group id
RG_ID=$(az group show -g $RG -o tsv --query id)

# VNet/Subnet Creation
VNET_NAME=reddog-vnet
az network vnet create \
-g $RG \
-n $VNET_NAME \
--address-prefix 10.140.0.0/16 \
--subnet-name aks \
--subnet-prefix 10.140.0.0/24

# Adding a subnet example
az network vnet subnet create \
--resource-group $RG \
--vnet-name $VNET_NAME \
--name AzureFirewallSubnet \
--address-prefix 10.140.1.0/24

# Get a subnet resource ID
az network vnet subnet show \
-g $RG \
--vnet-name $VNET_NAME  \
--name aks \
-o tsv \
--query id

# Create a managed identity
az identity create \
--name clusteridentity \
--resource-group $RG

# Get Managed Identity Resource ID
CLUSTER_IDENT_ID=$(az identity show \
--name clusteridentity \
-g $RG \
-o tsv \
--query principalId)

# Grant the Managed Identity Contributor on the Resource Group
az role assignment create \
--assignee $CLUSTER_IDENT_ID \
--role "Contributor" \
--scope "$RG_ID"
```


## Application Manifests and Deployment




