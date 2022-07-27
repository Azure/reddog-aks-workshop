# Enviornemnt Preparation

Before creating an enterprise ready AKS cluster there are some foundations you must lay down. The complexity of these foundations will depend heavily on the individual organization and their networking and security requirements. For example, some organizations are happy to create custers completely disconnected from their corporate network and allow for public IPs to be created from that cluster. Other organizations will enforce the use of a specific network location with pre-planned egress and ingress control in place. Some organizations allow Azure subscription owners the right to create identities and manage identity access within the subscription, while others strictly enforce centralized identity and access control.

For the purposes of this workshop we will assume an environment more like the latter, where control of ingress and egress traffic to the Kubernetes cluster must by strictly controlled. We will streamline where we can to speed up the workshop, but will also share links to documentation that will dive much deeper in those areas.

## Network Planning

Azure Kubernetes Service ultimately runs on virtual machines, and those virtual machines live in a subnet within an [Azure Virtual Network](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview). For this workshop we'll assume the following network requirements:

* You've been given the following address space to use for your environment 
  * 10.140.0.0/16
* The organization has limited available IP space, so you'll need to chose the AKS network plug-in that will use the fewest private IP addresses

**Task:**
Create the Resource Group and Azure Virtual Network and subnet that will be used for your AKS cluster.

> **Warning**
> You will be asked to add other components to the network later in the workshop, so make sure ou leave address space.

**Useful links:**
* [Azure CLI: Create VNet](https://docs.microsoft.com/en-us/cli/azure/network/vnet?view=azure-cli-latest#az-network-vnet-create)
* [AKS Networking Concepts](https://docs.microsoft.com/en-us/azure/aks/concepts-network)
* [Kubenet on AKS](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet)