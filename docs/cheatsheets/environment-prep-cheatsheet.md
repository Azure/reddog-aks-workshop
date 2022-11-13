## Environment Planning Cheatsheet

In environment planning you were given the following requirements:

* The cluster identity, used to make infrastructure changes should be a managed identity
* The cluster identity should have 'Contributor' rights on the Resource Group
* The identity used to pull images from the Azure Container Registry (i.e. the Kubelet identity) should be a managed identity

You were asked to complete the following tasks:

1. Create the Resource Group and Azure Virtual Network and subnet that will be used for your AKS cluster. 
2. Get the resource ID for the subnet where the AKS cluster will be deployed.
3. Create a managed identity for the cluster in the cluster resource group, with the rights documented in the requirements.
4. Create a managed identity to be used by Kubelet to pull images (**NOTE:** We'll set permissions for this identity in a later step.)


### Resource Group Creation

All resource in Azure are placed in a resource group, so we need to start there before creating any other resources:

```bash
# Resource Group Creation
RG=RedDogAKSWorkshop
LOC=eastus
az group create -g $RG -l $LOC
```

In later steps we may need the Azure Resource ID for the Resource Group. Here's how we get that:

```bash
# Get the resource group id
RG_ID=$(az group show -g $RG -o tsv --query id)
```


### VNet/Subnet Creation

Using the resource group we created previously, we create the Vnet and Subnet for both the AKS cluster and for the Azure Firewall.

```bash
# Set an environment variable for the VNet name
VNET_NAME=reddog-vnet

# Create the Vnet along with the initial subet for AKS
az network vnet create \
-g $RG \
-n $VNET_NAME \
--address-prefix 10.140.0.0/16 \
--subnet-name aks \
--subnet-prefix 10.140.0.0/24
```

When we create the AKS Cluster, we'll need the Azure Resource ID for the subnet where the cluster will be deployed. Here's how we get that:

```bash
# Get a subnet resource ID
az network vnet subnet show \
-g $RG \
--vnet-name $VNET_NAME  \
--name aks \
-o tsv \
--query id
```

### Create a managed identity

The tasks ask you to create a managed identity for the cluster as well as for Kubelet. Here are the commands to create a managed identity and to assign a role to the identity:

```bash
# Create a new managed identity
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

# Create a new managed identity
az identity create \
--name kubeletidentity \
--resource-group $RG
```

