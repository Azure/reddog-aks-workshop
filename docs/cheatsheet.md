# Cheat Sheet

## Environment Planning

```bash
# Resource Group Creation
RG=RedDogAKSWorkshop
LOC=eastus
az group create -g $RG -l $LOC

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

```


## Application Manifests and Deployment




