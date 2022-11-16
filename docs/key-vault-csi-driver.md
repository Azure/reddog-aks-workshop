# Key Vault CSI Driver

Getting secret values to your application, like credentials for external services and database connection strings, is critical to application delivery. The Key Vault CSI driver enables you to leverage the Kubernetes Container Storage Interface to mount Azure Key Vault data (i.e. secrets and certificates) as files or environment variables on your pod. In this step you'll enable the Key Vault CSI driver and then use it to pull a secret value into a pod.

## Pre-requisites

Make sure the following are complete before setting up the CSI driver

* Cluster is provisioned and accessible via 'kubectl'
* You've completed the Workload Identity lab

## Key Vault CSI Driver Requirements

* The Key Vault CSI Drive must be enabled on the AKS cluster as a managed add-on
* Workload Identity must be used to access the key vault, NOT pod identity
* A test pod must be created with a secret mounted in the following two ways:
  * Secret value mounted into a file
  * Secret value loaded into an environment variable
  

## Tasks:

1. Enable the Key Vault CSI driver managed add-on on the AKS cluster
2. Ensure Workload Identity is properly configured
3. Create the Managed Identity and Federated Service Principal that will access the key vault
4. Create the Key Vault and add a secret
5. Create the secret provider configuration
6. Deploy a pod that mounts the secret and test

**Useful links:**

* [Use the Azure Key Vault Provider for Secrets Store CSI Driver in an AKS cluster](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-driver)
* [Provide an identity to access the Azure Key Vault Provider ](https://learn.microsoft.com/en-us/azure/aks/csi-secrets-store-identity-access)
