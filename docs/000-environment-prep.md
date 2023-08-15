# Environment Preparation

Before creating an enterprise ready AKS cluster there are some foundations you must lay down. The complexity of these foundations will depend heavily on the individual organization and their networking and security requirements. For example, some organizations are happy to create clusters completely disconnected from their corporate network and allow for public IPs to be created from that cluster. Other organizations will enforce the use of a specific network location with pre-planned egress and ingress control in place. Some organizations allow Azure subscription owners the right to create identities and manage identity access within the subscription, while others strictly enforce centralized identity and access control.

For the purposes of this workshop we will assume an environment more like the latter, where control of ingress and egress traffic to the Kubernetes cluster must by strictly controlled. We will streamline where we can to speed up the workshop, but will also share links to documentation that will dive much deeper in those areas.

## Network Planning Requirements

Azure Kubernetes Service ultimately runs on virtual machines, and those virtual machines live in a subnet within an [Azure Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview). For this workshop we'll assume the following network requirements:

* You've been given the following address space to use for your environment 
  * 10.140.0.0/16

## Identity Planning Requirements

Since Azure Kubernetes Service needs to interact with Azure to make infrastructure changes (ex. Attaching disks to nodes for persistent volumes and modifying the cluster load balancer as Kubernetes services of type 'LoadBalancer' are exposed), you need identities created with appropriate rights.

* The cluster identity, used to make infrastructure changes should be a managed identity
* The cluster identity should have 'Contributor' rights on the Resource Group
* The identity used to pull images from the Azure Container Registry (i.e. the Kubelet identity) should be a managed identity

## Task:

1. Create the Resource Group and Azure Virtual Network and subnet that will be used for your AKS cluster. 
   > **Warning**
   >
   > You will be asked to add other components to the network later in the workshop, so make sure you leave address space.

2. Get the resource ID for the subnet where the AKS cluster will be deployed.
3. Create a managed identity for the cluster in the cluster resource group, with the rights documented in the requirements.
4. Create a managed identity to be used by Kubelet to pull images (**NOTE:** We'll set permissions for this identity in a later step.)

**Useful links:**

* [Azure CLI: Create VNet](https://docs.microsoft.com/en-us/cli/azure/network/vnet?view=azure-cli-latest#az-network-vnet-create)
* [AKS Networking Concepts](https://docs.microsoft.com/en-us/azure/aks/concepts-network)
* [Azure Managed Identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
* [Using Managed Identities with AKS](https://docs.microsoft.com/en-us/azure/aks/use-managed-identity)

### Next:

Once you've completed the above task you will need to decide if you plan to continue on the path to set up your environment with full Internet egress lockdown (i.e. all outbound traffic flowing through an egress firewall) or if you will allow all Internet egress traffic by default.

* **Option 1:** Continue to [Egress Lockdown](./optional-001-egress-lockdown.md) setup
* **Option 2:** Jump ahead to [Cluster Creation](./cluster-creation.md)
