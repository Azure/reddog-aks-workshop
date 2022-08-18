# Cluster Policy

You can think of a Kubernetes cluster like a personal cloud platform. Much like you have the need to create policys on your public cloud (ex. Azure Policy), you probably should apply policies on your Kubernetes clusters. For example, you may want to deny the creation of Pods with privileged access, except in certain namespaces. In this step you'll enable Azure Policy for AKS, which is built on the [Open Policy Agent - Gatekeeper](https://kubernetes.io/blog/2019/08/06/opa-gatekeeper-policy-and-governance-for-kubernetes/) project.

## Pre-requisites

Make sure the following are complete before setting up ingress.

* Cluster is provisioned and accessible via 'kubectl'
* App Deployment is complete

## Cluster Policy Requirements

* Azure Policy for AKS must be enabled on the cluster
* Creation of privileged pods should be blocked for all namespaces except kube-system, gatekeeper-system and azure-arc
* The scope of the policy assignment should be only the resource group where the AKS cluster is deployed
  

## Tasks:

1. Enable Policy on the AKS Cluster
2. Apply the privileged pod policy at the cluster level
3. Test the policy is operating as expected

**Useful links:**

* [Open Policy Agent - Gatekeeper](https://kubernetes.io/blog/2019/08/06/opa-gatekeeper-policy-and-governance-for-kubernetes/)
* [What is Azure Policy?](https://docs.microsoft.com/en-us/azure/governance/policy/overview)
* [Azure Policy for Kubermetes](https://docs.microsoft.com/en-us/azure/governance/policy/concepts/policy-for-kubernetes)
* [Secure your cluster with Azure Policy](https://docs.microsoft.com/en-us/azure/aks/use-azure-policy?toc=%2Fazure%2Fgovernance%2Fpolicy%2Ftoc.json&bc=%2Fazure%2Fgovernance%2Fpolicy%2Fbreadcrumb%2Ftoc.json)