## Workload Identity Cheatsheet

In workload identity, you were given the following requirements:

* The new Azure Workload Identity feature must be enabled on the existing AKS cluster
* A new Managed Identity should be created in the cluster resource group
* A new Kubernetes Service Account must be created in a new namespace
* The Managed Identity and Service Account must be federated using the cluster OIDC Issuer
* Via custom code, you must demonstrate an authenticated connection to an AAD Auth enabled endpoint to retrieve data

You were asked to complete the following tasks:

1. Enable the cluster for AAD Workload Identity
2. Create the AAD side and cluster side identities
3. Configure an AAD enabled target for testing
4. Write the code to test your Workload Identity setup
5. Deploy the application to your AKS cluster and demonstrate it's operation


### Enable the cluster for AAD Workload Identity

At the time of writing this cheatsheet the Azure Workload Identity managed add-on is still in preview. The first thing we need to do is to make sure we have the feature enabled in our Azure CLI as well as on the target subscription. 

```bash
# Add or update the Azure CLI aks preview extension
az extension add --name aks-preview
az extension update --name aks-preview

# Register for the preview feature
az feature register --namespace "Microsoft.ContainerService" --name "EnableWorkloadIdentityPreview"

# Check registration status
az feature list -o table --query "[?contains(name, 'Microsoft.ContainerService/EnableWorkloadIdentityPreview')].{Name:name,State:properties.state}"

# Once the registration status shows 'Registered' you can continue to the next command

# Refresh the provider
az provider register --namespace Microsoft.ContainerService
```

Now to enable the Azure Workload Identity managed add-on and OIDC issuer on the target cluster.

```bash
RG=[RESOURCE GROUP NAME]
CLUSTER_NAME=[CLUSTER NAME]

az aks update -g $RG -n $CLUSTER_NAME \
--enable-oidc-issuer \
--enable-workload-identity
```

### Create the AAD side and cluster side identities

Now that the cluster is enabled with the OIDC Issuer and Azure Workload Identity, we can create our Managed Identity and Service Account and then federate those identities.

```bash
MANAGED_IDENTITY_NAME=testmi

# Get the OIDC Issuer URL
export AKS_OIDC_ISSUER="$(az aks show -n $CLUSTER_NAME -g $RG --query "oidcIssuerProfile.issuerUrl" -o tsv)"

# Create the managed identity
az identity create --name $MANAGED_IDENTITY_NAME --resource-group $RG

# Get identity client ID
export USER_ASSIGNED_CLIENT_ID=$(az identity show --resource-group $RG --name $MANAGED_IDENTITY_NAME --query 'clientId' -o tsv)

# Create the namespace and service account
NAMESPACE=workload-identity-test

kubectl create ns $NAMESPACE

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  annotations:
    azure.workload.identity/client-id: ${USER_ASSIGNED_CLIENT_ID}
  labels:
    azure.workload.identity/use: "true"
  name: ${MANAGED_IDENTITY_NAME}-sa
  namespace: ${NAMESPACE}
EOF

# Finally, federate the two identities
# Federate the identity
az identity federated-credential create \
--name $MANAGED_IDENTITY_NAME-federated-id \
--identity-name $MANAGED_IDENTITY_NAME \
--resource-group $RG \
--issuer ${AKS_OIDC_ISSUER} \
--subject system:serviceaccount:$NAMESPACE:$MANAGED_IDENTITY_NAME-sa
```

### Configure an AAD enabled target for testing

For the purposes of this test, one of the best and easiest sample targets is Azure Key Vault. So lets create an Azure Key Vault and a Secret that we can try to access from our cluster. 

> *Note:* The key vault name must be unique.

```bash
KEY_VAULT_NAME=griffith-kv

# Create a key vault
az keyvault create --name $KEY_VAULT_NAME --resource-group $RG

# Create a secret
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "Secret" --value "Hello from key vault"

# Grant access to the secret for the managed identity using it's AAD client ID
az keyvault set-policy --name $KEY_VAULT_NAME --secret-permissions get --spn "${USER_ASSIGNED_CLIENT_ID}"

```

### Write the code to test your Workload Identity setup

If you wish to write the code and build a test container from scratch you can continue with this section.  Otherwise you can just skip to the [Super Cheat](#super-cheat) Section Below.

Now we have our cluster setup properly and have created a test target for an AAD authenticated call. Let's write some code to call the key vault. In this case we'll use dotnet, but you can use any language you prefer that is supported by the [Microsoft Authentication Libraries](https://learn.microsoft.com/en-us/azure/active-directory/develop/reference-v2-libraries).

```bash
# Create and test a new console app
dotnet new console -n keyvault-console-app
cd keyvault-console-app
dotnet run

# Add the Key Vault and Azure Identity Packages
dotnet add package Azure.Security.KeyVault.Secrets
dotnet add package Azure.Identity
```

Edit the Program.cs file as follows:

```csharp
using System;
using System.IO;
using Azure.Core;
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;

class Program
    {
        static void Main(string[] args)
        {
            //Get env variables
            string? secretName = Environment.GetEnvironmentVariable("SECRET_NAME");;
            string? keyVaultName = Environment.GetEnvironmentVariable("KEY_VAULT_NAME");;
            
            //Create Key Vault Client
            var kvUri = String.Format("https://{0}.vault.azure.net", keyVaultName);
            SecretClientOptions options = new SecretClientOptions()
            {
                Retry =
                {
                    Delay= TimeSpan.FromSeconds(2),
                    MaxDelay = TimeSpan.FromSeconds(16),
                    MaxRetries = 5,
                    Mode = RetryMode.Exponential
                 }
            };

            var client = new SecretClient(new Uri(kvUri), new DefaultAzureCredential(),options);

            // Get the secret value in a loop
            while(true){
            Console.WriteLine("Retrieving your secret from " + keyVaultName + ".");
            KeyVaultSecret secret = client.GetSecret(secretName);
            Console.WriteLine("Your secret is '" + secret.Value + "'.");
            System.Threading.Thread.Sleep(5000);
            }

        }
    }
```

We need to get this app into a container, so lets create a new Dockerfile with the following:

```bash
FROM mcr.microsoft.com/dotnet/sdk:6.0 AS build-env
WORKDIR /App

# Copy everything
COPY . ./
# Restore as distinct layers
RUN dotnet restore
# Build and publish a release
RUN dotnet publish -c Release -o out

# Build runtime image
FROM mcr.microsoft.com/dotnet/aspnet:6.0
WORKDIR /App
COPY --from=build-env /App/out .
ENTRYPOINT ["dotnet", "keyvault-console-app.dll"]
```

Now we need to build the image. You can do this locally, but to be safe from any cpu architecture mismatches, lets use the Azure Container Registry to build. You should have an existing registry from the [Container Registry Lab](./container-registry-cheatsheet.md).

```bash
ACR_NAME=[ACR NAME]
IMAGE_NAME=wi-kv-test

# Build the image
az acr build -t $IMAGE_NAME -r $ACR_NAME .

# Get the ACR FQDN for later
ACR_FQDN=$(az acr show -n $ACR_NAME -o tsv --query loginServer)

```


### Deploy the application to your AKS cluster and demonstrate it's operation

Now all we need to do is create a pod that uses our federated service account with our test app loaded!

```bash
# First get the namespace and service account names
kubectl get ns

# Sample Output
NAME                     STATUS   AGE
default                  Active   53m
kube-node-lease          Active   53m
kube-public              Active   53m
kube-system              Active   53m
workload-identity-test   Active   40m

# Set the Namespace name
NAMESPACE=workload-identity-test

kubectl get sa -n $NAMESPACE

# Sample Output
NAME        SECRETS   AGE
default     1         41m
testmi-sa   1         41m

# Set the service account name
SA_NAME=testmi-sa

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: wi-kv-test
  namespace: ${NAMESPACE}
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: ${SA_NAME}
  containers:
    - image: ${ACR_FQDN}/${IMAGE_NAME}
      name: wi-kv-test
      env:
      - name: KEY_VAULT_NAME
        value: ${KEY_VAULT_NAME}
      - name: SECRET_NAME
        value: Secret    
  nodeSelector:
    kubernetes.io/os: linux
EOF

# Check the pod status
kubectl get pods -n $NAMESPACE

# Sample Output
NAME         READY   STATUS    RESTARTS   AGE
wi-kv-test   1/1     Running   0          2m9s

# Now check the logs
kubectl logs -f wi-kv-test -n $NAMESPACE

# Sample Output
Retrieving your secret from griffith-kv.
Your secret is 'Hello from key vault'.
Retrieving your secret from griffith-kv.
Your secret is 'Hello from key vault'.
Retrieving your secret from griffith-kv.
Your secret is 'Hello from key vault'.
```

You now have a cluster enabled with the OIDC Issuer and the Azure Workload Identity managed add-on with a deployed application using a Kubernetes Service Account that has been federated to an Azure Managed Identity to access a secret in an Azure Key Vault!


### Super Cheat

NOTE: if you deployed with the optional egress-lock down with firewall you must ensure that there is a rule that allows ```ghcr.io``` as an egress FQDN on port ```:443``` as your cluster will be pulling a container image from our package repo. 

Now all we need to do is create a pod that uses our federated service account with our test app loaded!

```bash
# First get the namespace and service account names
kubectl get ns

# Sample Output
NAME                     STATUS   AGE
default                  Active   53m
kube-node-lease          Active   53m
kube-public              Active   53m
kube-system              Active   53m
workload-identity-test   Active   40m

# Set the Namespace name
NAMESPACE=workload-identity-test

kubectl get sa -n $NAMESPACE

# Sample Output
NAME        SECRETS   AGE
default     1         41m
testmi-sa   1         41m

# Set the service account name
SA_NAME=testmi-sa

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: wi-kv-test
  namespace: ${NAMESPACE}
  labels:
    azure.workload.identity/use: "true"
spec:
  serviceAccountName: ${SA_NAME}
  containers:
    - image: ghcr.io/azure/reddog-aks-workshop/workload-identity-app:latest
      name: wi-kv-test
      env:
      - name: KEY_VAULT_NAME
        value: ${KEY_VAULT_NAME}
      - name: SECRET_NAME
        value: Secret    
  nodeSelector:
    kubernetes.io/os: linux
EOF

# Check the pod status
kubectl get pods -n $NAMESPACE

# Sample Output
NAME         READY   STATUS    RESTARTS   AGE
wi-kv-test   1/1     Running   0          2m9s

# Now check the logs
kubectl logs -f wi-kv-test -n $NAMESPACE

# Sample Output
Retrieving your secret from griffith-kv.
Your secret is 'Hello from key vault'.
Retrieving your secret from griffith-kv.
Your secret is 'Hello from key vault'.
Retrieving your secret from griffith-kv.
Your secret is 'Hello from key vault'.
```

You now have a cluster enabled with the OIDC Issuer and the Azure Workload Identity managed add-on with a deployed application using a Kubernetes Service Account that has been federated to an Azure Managed Identity to access a secret in an Azure Key Vault!
