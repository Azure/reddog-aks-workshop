# Setting up and using Workload Identity

Identity control is one of the most critical security requirements for any application. Not only control of the identities used to access your application, but control of the identities your application uses to access other systems. In this workshop we'll work through enabling Azure Active Directory Workload Identity and using that identity from an application.

## Pre-requisites

Make sure the following are complete before setting up ingress.

* Cluster is provisioned and accessible via 'kubectl'

## Workload Identity Requirements

* The new Azure Workload Identity feature must be enabled on the existing AKS cluster
* A new Managed Identity should be created in the cluster resource group
* A new Kubernetes Service Account must be created in a new namespace
* The Managed Identity and Service Account must be federated using the cluster OIDC Issuer
* Via custom code, you must demostrate an authenticated connection to an AAD Auth enabled endpoint to retrieve data


## Tasks:

1. Enable the cluster for AAD Workload Identity
2. Create the AAD side and cluster side identities
3. Configure an AAD enabled target for testing
4. Write the code to test your Workload Identity setup
5. Deploy the application to your AKS cluster and demonstrate it's operation

**Useful links:**

* [Azure Workload Identity](https://azure.github.io/azure-workload-identity/docs/)
* [AKS OIDC Issuer](https://learn.microsoft.com/en-us/azure/aks/cluster-configuration#oidc-issuer)
* [AKS Workload Identity Add-On](https://learn.microsoft.com/en-us/azure/aks/workload-identity-deploy-cluster)
* [Microsoft Identity Library (MSAL)](https://learn.microsoft.com/en-us/azure/active-directory/develop/reference-v2-libraries)
