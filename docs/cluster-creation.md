# Cluster Creation Overview

In previous steps you should have created the network foundation for your cluster, including the Azure Firewall and rules required by AKS. You also created identities for the cluster and kublet. Now you'll need to bring those together in creation of an AKS cluster.

## AKS Cluster Requirements

* The organization has limited available IP space, so you'll need to choose the AKS network plug-in that will use the fewest private IP addresses
* The cluster must be created in the 'aks' subnet you created previously
* The cluster should be configured so that outbound traffic uses the route table you've created which forces internet traffic to the Azure Firewall
* The cluster should use the following address spaces:
    * Pod CIDR: 10.244.0.0/24
    * Service CIDR: 10.245.0.0/24
    * DNS Service IP: 10.245.0.10
* The cluster should use the cluster and kubelet identities you've already created
* The cluster should have both a 'System' and 'User' mode nodepool
* The 'System' mode pool should be tainted to only allow system pods

## Task:

1. Using the requirements above, construct a command to deploy your AKS cluster (Review with your proctor before deploying)
2. Deploy the cluster
3. Get the cluster credentials and check that all nodes are in a 'READY' state and all pods are in 'Running' state

**Useful links:**

* [Kubenet on AKS](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet)
* [Azure CNI on AKS](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
* [AKS Egress Lockdown](https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic)
* [Azure Managed Identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
* [Using Managed Identities with AKS](https://docs.microsoft.com/en-us/azure/aks/use-managed-identity)
* [AKS User and System Pools](https://docs.microsoft.com/en-us/azure/aks/use-system-pools?tabs=azure-cli)