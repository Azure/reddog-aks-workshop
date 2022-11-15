## Cluster Creation Cheatsheet

In cluster creation, you were given the following requirements:

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

You were asked to complete the following tasks:

1. Using the requirements above, construct a command to deploy your AKS cluster (Review with your proctor before deploying)
2. Deploy the cluster
3. Get the cluster credentials and check that all nodes are in a 'READY' state and all pods are in 'Running' state

### Gather Required Variables

In prior steps we create a Virtual Network and a Subnet for the AKS cluster. We also created Managed Identities for the cluster and the kubelet service. We need to get those values and set them as Environment Variables that we can use in our cluster creation command.

> **Note**
> Make sure you review all commands below to be sure any changes you made to the resource names are applied.

```bash
# Set the Environment Variables used in the lookups
RG=RedDogAKSWorkshop
VNET_NAME=reddog-vnet
SUBNET_NAME=aks
CLUSTER_IDENTITY_NAME=clusteridentity
KUBELET_IDENTITY_NAME=kubeletidentity

# Get the cluster VNet Subnet ID
VNET_SUBNET_ID=$(az network vnet subnet show -g $RG --vnet-name $VNET_NAME -n $SUBNET_NAME -o tsv --query id)

# Get the Cluster Identity ID
CLUSTER_IDENTITY_ID=$(az identity show -g $RG -n $CLUSTER_IDENTITY_NAME -o tsv --query id)

# Get the Kubelet Identity ID
KUBELET_IDENTITY_ID=$(az identity show -g $RG -n $KUBELET_IDENTITY_NAME -o tsv --query id)
```

### Create the Cluster

Given the requirements we will set the following in our cluster creation command:

* Our cluster creation command will specify a target Vnet/Subnet
* We'll choose [kubenet](https://docs.microsoft.com/en-us/azure/aks/configure-kubenet) as the network plugin, as it requires the least IP space
* Configure the cluster egress model:
  * **If you followed the egress lockdown path**, set the 'OutboundType' to use 'UserDefinedRouting'
  * **If you didn't follow the egress lockdown path**, set the 'OutboundType' to use 'LoadBalancer', or don't set it at all as this is the default value
* We'll set the following address ranges (CIDRs)
    * Pod CIDR: 10.244.0.0/24
    * Service CIDR: 10.245.0.0/24
    * DNS Service IP: 10.245.0.10
* We'll set the network policy to use 'calico'
* We'll provide the command the resource IDs for both the kubelet and cluster identities

```bash
# NOTE: Make sure you give your cluster a unique name
CLUSTER_NAME=reddog-griffith

# Cluster Creation Command

# NOTE: You only need to set --outbound-type if you followed the egress
# lockdown approach. If you didn't, then set it to 'LoadBalancer' or leave it
# off entirely, as 'LoadBalancer' is the default value.
az aks create \
-g $RG \
-n $CLUSTER_NAME \
--nodepool-name systempool \
--network-plugin kubenet \
--network-policy calico \
--vnet-subnet-id $VNET_SUBNET_ID \
--pod-cidr 10.244.0.0/16 \
--service-cidr 10.245.0.0/24 \
--dns-service-ip 10.245.0.10 \
--outbound-type userDefinedRouting \
--enable-managed-identity \
--assign-identity $CLUSTER_IDENTITY_ID \
--assign-kubelet-identity $KUBELET_IDENTITY_ID \
--generate-ssh-keys
```

### Connect to the Cluster

Now that the cluster has successfuly completed, we need to get the credentials and check it out. If you havent already, make sure you have [kubectl](https://kubernetes.io/docs/tasks/tools/) installed.

```bash
# Get the cluster credentials
az aks get-credentials -g $RG -n $CLUSTER_NAME

# Check the nodes are online and in 'Ready' state
kubectl get nodes
NAME                                 STATUS   ROLES   AGE     VERSION
aks-systempool-49954760-vmss000000   Ready    agent   2m40s   v1.22.11
aks-systempool-49954760-vmss000001   Ready    agent   2m44s   v1.22.11
aks-systempool-49954760-vmss000002   Ready    agent   2m45s   v1.22.11

# Check the pods in the 'kube-system' namespace are all up and in 'Running' state
kubectl get pods -n kube-system
NAME                                  READY   STATUS    RESTARTS   AGE
cloud-node-manager-66vms              1/1     Running   0          3m3s
cloud-node-manager-b2jfh              1/1     Running   0          3m2s
cloud-node-manager-xh4mx              1/1     Running   0          2m58s
coredns-autoscaler-7d56cd888-plccq    1/1     Running   0          4m47s
coredns-dc97c5f55-8nqs5               1/1     Running   0          66s
coredns-dc97c5f55-bm42b               1/1     Running   0          4m46s
csi-azuredisk-node-7fgtw              3/3     Running   0          3m2s
csi-azuredisk-node-prhg7              3/3     Running   0          3m3s
csi-azuredisk-node-sf85m              3/3     Running   0          2m58s
csi-azurefile-node-82wcc              3/3     Running   0          2m58s
csi-azurefile-node-9mszz              3/3     Running   0          3m2s
csi-azurefile-node-l8w87              3/3     Running   0          3m3s
konnectivity-agent-74cd47f88d-8r4qj   1/1     Running   0          4m46s
konnectivity-agent-74cd47f88d-l4wff   1/1     Running   0          4m46s
kube-proxy-jj2js                      1/1     Running   0          2m58s
kube-proxy-px2rf                      1/1     Running   0          3m3s
kube-proxy-sgxs6                      1/1     Running   0          3m2s
metrics-server-64b66fbbc8-t8wkp       1/1     Running   0          4m46s
```

### Create a new 'User' mode nodepool and taint the System pool


```bash
# Name the user pool
USER_POOL_NAME=userpool

# Add the nodepool
az aks nodepool add \
--resource-group $RG \
--cluster-name $CLUSTER_NAME \
--name $USER_POOL_NAME \
--mode User

# Check that your new nodes are online
kubectl get nodes
NAME                                STATUS   ROLES   AGE     VERSION
aks-nodepool1-41586636-vmss000000   Ready    agent   69m     v1.22.11
aks-nodepool1-41586636-vmss000001   Ready    agent   70m     v1.22.11
aks-nodepool1-41586636-vmss000002   Ready    agent   69m     v1.22.11
aks-userpool-38173843-vmss000000    Ready    agent   3m5s    v1.22.11
aks-userpool-38173843-vmss000001    Ready    agent   3m22s   v1.22.11
aks-userpool-38173843-vmss000002    Ready    agent   3m16s   v1.22.11


# Apply a taint to the default pool so that it will be for system resources only
# Note: Alternatively, you could have set this in the cluster creation step
az aks nodepool update \
--resource-group $RG \
--cluster-name $CLUSTER_NAME \
--name systempool \
--node-taints CriticalAddonsOnly=true:NoSchedule

# Check that the taint has been applied to the default nodepool
az aks nodepool update \
--resource-group $RG \
--cluster-name $CLUSTER_NAME \
--name systempool \
--query nodeTaints
```
