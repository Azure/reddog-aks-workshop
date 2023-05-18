# Egress Lockdown Overview

Controlling the flow of traffic leaving the cluster, in particular to the public Internet is often a critical requirement. In this workshop we'll work through the setup of a firewall and the routing rules required to ensure only approved destinations are reachable from the Azure Kubernetes Service Cluster.

> **Note**
> We will be deploying the cluster in a later step. Right now the focus is on laying the required network components that will be used later.

## Egress Lockdown Requirements

* Azure Firewall should be used to control outbound network traffic
* The Azure Firewall should have DNS Proxy enabled
* The subnet which will host the Azure Kubernetes Service cluster should force internet traffic (default route 0.0.0.0/0) to the Azure Firewall
* The Azure Firewall should allow the following list of IPs and FQDNs, as described in the [AKS Egress Lockdown](https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic) doc

    |Address |Protocol |Ports |
    | ---- | ---- | ---- |
    |AzureCloud.\<region\>|UDP|1194|
    |AzureCloud.\<region\>|TCP|9000, 443|
    |ntp.ubuntu.com|UDP|123|
    |AzureKubernetesService|TCP|80, 443|
    |mcr.microsoft.com|TCP|80, 443|
    |*.data.mcr.microsoft.com|TCP|80, 443|
    |management.azure.com|TCP|80, 443|
    |login.microsoftonline.com|TCP|80, 443|
    |packages.microsoft.com|TCP|80, 443|
    |acs-mirror.azureedge.net|TCP|80, 443|

## Task:

1. Create a subnet for the Azure Firewall
2. Create and configure the Azure Firewall
3. Create and configure the Azure Route table

**Useful links:**

* [AKS Egress Lockdown](https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic)
* [AKS Outbound Type Options](https://docs.microsoft.com/en-us/azure/aks/egress-outboundtype)
* [What is Azure Firewall](https://docs.microsoft.com/en-us/azure/firewall/overview)
* [Virtual Network Traffic Routing](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-udr-overview)
* [Managing Azure Route Tables](https://docs.microsoft.com/en-us/azure/virtual-network/manage-route-table)

### Next:

Now that you have the network prepared to host your secure AKS cluster, you're ready to continue on to the [Cluster Creation](./cluster-creation.md) step.