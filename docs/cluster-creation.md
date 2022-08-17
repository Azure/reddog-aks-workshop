# Cluster Creation Overview

In previous steps you should have created the network and identity foundations for your cluster. You may have also set up the infrastructure for egress lockdown, including the Azure Firewall and rules required by AKS. Now it's time to bring those together in creation of an AKS cluster.

## AKS Cluster Requirements

* The organization has limited available IP space, so you'll need to choose the AKS network plug-in that will use the fewest private IP addresses
* The cluster must be created in the 'aks' subnet you created previously
* **If you followed the egress lockdown path**, the cluster should be configured so that outbound traffic uses the route table you've created which forces internet traffic to the Azure Firewall, otherwise you can use the default cluster egress model.
* The cluster should use the following address spaces:
    * Pod CIDR: 10.244.0.0/16
    * Service CIDR: 10.245.0.0/24
    * DNS Service IP: 10.245.0.10
* The cluster should use the cluster and kubelet identities you've already created
* The cluster should be configured to use 'Calico' Kubernetes Network Policy
* The cluster should have both a 'System' and 'User' mode nodepool
* The initial pool created will be the system pool and should be called 'systempool'
* The 'System' mode pool should be tainted to only allow system pods

## Task:

1. Using the requirements above, construct a command to deploy your AKS cluster (Review with your proctor before deploying)
2. Deploy the cluster
3. Get the cluster credentials and check that all nodes are in a 'READY' state and all pods are in 'Running' state

**Useful links:**

* [Kubenet on AKS](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet)
* [Azure CNI on AKS](https://docs.microsoft.com/en-us/azure/aks/configure-azure-cni)
* [Calico Network Policy](https://docs.microsoft.com/en-us/azure/aks/use-network-policies#create-an-aks-cluster-for-calico-network-policies)
* [AKS Egress Lockdown](https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic)
* [Azure Managed Identities](https://docs.microsoft.com/en-us/azure/active-directory/managed-identities-azure-resources/overview)
* [Using Managed Identities with AKS](https://docs.microsoft.com/en-us/azure/aks/use-managed-identity)
* [AKS User and System Pools](https://docs.microsoft.com/en-us/azure/aks/use-system-pools?tabs=azure-cli)

### Next:

[App Deploy](app-deployment.md)