## Key Vault CSI Driver Setup Cheatsheet

In Key Vault CSI Driver setup, you were given the following requirements:

* The Key Vault CSI Drive must be enabled on the AKS cluster as a managed add-on
* Workload Identity must be used to access the key vault, NOT pod identity
* A test pod must be created with a secret mounted in the following two ways:
  * Secret value mounted into a file
  * Secret value loaded into an environment variable

You were asked to complete the following tasks:

1. Enable the Key Vault CSI driver managed add-on on the AKS cluster
2. Ensure Workload Identity is properly configured
3. Create the Managed Identity, Namespace and Federated Service Account that will access the key vault
4. Create the Key Vault and add a secret
5. Create the secret provider configuration
6. Deploy a pod that mounts the secret and test


### Enable the Key Vault CSI driver managed add-on on the AKS cluster

Since the pre-reqs noted that we shoudl have already completed the cluster creation lab, we'll just apply this on our existing AKS Cluster. 

> *Note:* We were specifically asked to use the managed add-on for AKS. That's because you can also deploy the Key Vault CSI driver using the open source project's helm chart directly, but then you are responsible for the support and maintenance of that deployment rather than using the AKS managed capability.

```bash
# Set the environment varibles for the existing cluster resource group and cluster name
RG=[CLUSTER RESOURCE GROUP]
CLUSTER_NAME=[CLUSTER NAME]

# Enable the Key Vault CSI Driver add-on
az aks enable-addons \
--addons azure-keyvault-secrets-provider \
--name $CLUSTER_NAME \
--resource-group $RG
```

### Ensure Workload Identity is properly configured

The pre-reqs said that you should have completed the [Azure Workload Identity](workload-identity-cheatsheet.md) lab before this. Lets confirm that it's enabled.

```bash
# Check that the OIDC Issuer is enabled
az aks show -g $RG -n $CLUSTER_NAME -o yaml --query oidcIssuerProfile

# Sample Output
enabled: true
issuerUrl: https://eastus.oic.prod-aks.azure.com/72f988bf-86f1-41af-91ab-2d7cd011db47/ef91e4ee-e549-44cc-9426-5dd7b9c1c3d0/

# Check that the Workload Identity add-on is enabled
az aks show -g $RG -n $CLUSTER_NAME -o yaml --query securityProfile.workloadIdentity

# Sample Output
enabled: true
```

If the above is not set up, you should got back to complete the [Azure Workload Identity](workload-identity-cheatsheet.md) lab.


### Create the Managed Identity, Namespace and Federated Service Account that will access the key vault

Since Azure Workload Identity allows us to bind a managed identity to a Kubernetes service account, we need to create the managed identity and then create a namespace for our application and an associated service account in that namespace. Then we can set up the managed identity to service account federation.

```bash
MANAGED_IDENTITY_NAME=kv-csi-mi

# Get the OIDC Issuer URL
export AKS_OIDC_ISSUER="$(az aks show -n $CLUSTER_NAME -g $RG --query "oidcIssuerProfile.issuerUrl" -otsv)"

# Create the managed identity
az identity create --name $MANAGED_IDENTITY_NAME --resource-group $RG

# Get identity client ID
export USER_ASSIGNED_CLIENT_ID=$(az identity show --resource-group $RG --name $MANAGED_IDENTITY_NAME --query 'clientId' -o tsv)

# Create the namespace and service account
NAMESPACE=kv-csi-test

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

### Create the Key Vault and add a secret

If you created a Key Vault in your Azure Workload Identity lab, then you can re-use that here, or you can follow these steps to create a key vault and secret.

> *Note:* They Key Vault name must be unique.

```bash
KEY_VAULT_NAME=griff-kv

# Create a key vault
az keyvault create --name $KEY_VAULT_NAME --resource-group $RG

# Create a secret
az keyvault secret set --vault-name $KEY_VAULT_NAME --name "Secret" --value "Hello from key vault"

# Grant access to the secret for the managed identity using it's AAD client ID
az keyvault set-policy --name $KEY_VAULT_NAME --secret-permissions get --spn "${USER_ASSIGNED_CLIENT_ID}"

```

### Create the secret provider configuration

Now that we have the identity configuration complete, and the key vault is set up with a secret that our managed identity is authorized to retrieve, we can do the final plumbing to enable the key vault CSI driver. This involves creating a SecretProviderClass. This provider class is the glue that tells Kubernetes how to access the secret.

We'll set up both the parameters to map the secret to the provide as well as the 'secretObjects' which will ensure that a Kubernetes Secret is also created and synchronized with the Key Vault secret. This is how we can mount the environment variable in the pod.

```bash
# Get the Key Vault Tenant ID
IDENTITY_TENANT=$(az keyvault show -g $RG -n $KEY_VAULT_NAME -o tsv --query properties.tenantId)

cat <<EOF | kubectl apply -f -
# This is a SecretProviderClass example using workload identity to access your key vault
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: ${KEY_VAULT_NAME}-provider # needs to be unique per namespace
  namespace: ${NAMESPACE}
spec:
  provider: azure
  parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "false"          
    clientID: "${USER_ASSIGNED_CLIENT_ID}" # Setting this to use workload identity
    keyvaultName: ${KEY_VAULT_NAME}       # Set to the name of your key vault
    objects:  |
      array:
        - |
          objectName: Secret
          objectType: secret              # object types: secret, key, or cert
    tenantId: "${IDENTITY_TENANT}"        # The tenant ID of the key vault
  secretObjects:                              # [OPTIONAL] SecretObjects defines the desired state of synced Kubernetes secret objects
  - data:
    - key: kv-secret                           # data field to populate
      objectName: Secret                        # name of the mounted content to sync; this could be the object name or the object alias
    secretName: test-secret                     # name of the Kubernetes secret object
    type: Opaque
EOF
```


### Deploy a pod that mounts the secret and test

Now that we have the Secreat Provider Class, we can create a pod that references that class. We'll mount a volume that directly references the provider class. We'll also create an environment variable that is linked to the Kubernetes secret that the CSI driver created using our 'secretObjects' configuration above.

```bash
# Deploy a pod with both the environment variable and volume configurations appliec
cat <<EOF | kubectl apply -f -
kind: Pod
apiVersion: v1
metadata:
  name: test-pod
  namespace: ${NAMESPACE}
spec:
  serviceAccountName: ${MANAGED_IDENTITY_NAME}-sa
  containers:
    - name: busybox
      image: k8s.gcr.io/e2e-test-images/busybox:1.29-1
      command:
        - "/bin/sleep"
        - "10000"
      volumeMounts:
      - name: secrets-store01-inline
        mountPath: "/mnt/secrets-store"
        readOnly: true
      env:
      - name: SECRET_FROM_KV
        valueFrom:
          secretKeyRef:
            name: test-secret
            key: kv-secret
  volumes:
    - name: secrets-store01-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "${KEY_VAULT_NAME}-provider"
EOF

# Check the secret is mounted to a volume
kubectl exec test-pod -n $NAMESPACE -- cat /mnt/secrets-store/Secret

# Sample Output
Hello from key vault

# Check the secret is loaded as an environment variable
kubectl exec test-pod -n $NAMESPACE -- env|grep SECRET_FROM_KV

# Sample Output
SECRET_FROM_KV=Hello from key vault

# Finally, for fun, lets look at the secret that was automatically created for us
# We'll need to get the value and then base64 decode it
kubectl get secret test-secret -n $NAMESPACE -o jsonpath='{.data.kv-secret}'|base64 -d

# Sample Output
Hello from key vault
```

You should now now a cluster with the following:

1. Key Vault CSI Driver enabled on the AKS cluster
2. An Azure Key Vault with a test secret, a 
3. A managed identity authorized to that secret that is also federated to a Kubenretes Service Account
4. A SecretProviderClass configured to create the binding from the cluster to the secret in Key Vault
5. A pod that mounts the secret as both a file and an environment variable

Great work!