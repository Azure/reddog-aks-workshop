# Network Policy

Controlling network traffic is typically best handled as close to the metal as possible, via route control, egress firewall and network security groups. However, there is a lot of benefit to further tuning your traffic control and implementing micro-segmentation within your Kubernetes cluster. 

## Pre-requisites

Make sure the following are complete before setting up network policies.

* Cluster is provisioned and accessible via 'kubectl'
* Cluster was provisioned with calico network policy, as per the cluster creation requirements
* App Deployment is complete

## Ingress Control Requirements

* The reddog namespace should deny all ingress traffic by default
* The reddog namespace should allow ingress traffic only from the ingress controller namespace and itself

## Tasks:

1. Verify that calico is installed
2. Create the ingress network policy

**Useful links:**

* [Kubernetes Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
* [AKS Network Policies](https://docs.microsoft.com/en-us/azure/aks/use-network-policies)
* [Cillium Network Policy Editor](https://editor.cilium.io/)
