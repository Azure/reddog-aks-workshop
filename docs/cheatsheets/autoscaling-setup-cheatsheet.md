## Autoscaling Setup Cheatsheet

In autoscaling setup, you were given the following requirements:

* Cluster autoscaler should be enabled on both the System and User mode nodepools
  * System pool should have a min count of 1 and max count of 3
  * User pool should have a min count of 0 and a max count of 3
* Since were rapid testing we want the cluster autoscaler to:
  *  Scan every 5 seconds for scale up
  *  Scale down when a node isn't needed for 1 minute
  *  Allow scale down 1m after scale up

You were asked to complete the following tasks:

1. Configure autoscaling for all nodepools based on the requirements above
2. Validate pod autoscaling is working
3. Validate cluster autoscaling is working

### Configure Autoscaling on Nodepools

In prior steps we created and AKS cluster. AKS enables the Kubernetes Horizontal Pod Autoscaler by default, so no action needed there, but you do need to enable the cluster autoscaler. You were asked to configure slightly different options on system pool and the user pool. One of the requirements was to adjust the autoscaler settings, which we can do using the AKS [Cluster Autoscale Profile](https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler#using-the-autoscaler-profile).


> **NOTE**
> The autoscale profile is a SYSTEM WIDE setting, so you need to update that at the cluster level, not on the individual nodepools.

Lets start with the system nodepool:

```bash
# Set the Environment Variables used in the lookups
RG=RedDogAKSWorkshop
CLUSTER_NAME=reddog-griffith

# First get the nodepool names
z aks nodepool list -g $RG --cluster-name $CLUSTER_NAME
Name        OsType    KubernetesVersion    VmSize           Count    MaxPods    ProvisioningState    Mode
----------  --------  -------------------  ---------------  -------  ---------  -------------------  ------
systempool  Linux     1.22.11              Standard_DS2_v2  3        110        Succeeded            System
userpool    Linux     1.22.11              Standard_DS2_v2  3        110        Succeeded            User

# Using the above output, set the nodepool names
SYSTEMPOOL_NAME=systempool
USERPOOL_NAME=userpool

# Based on the requirements, enable the cluster autoscaler on the system pool
# Requirments said min of 1 and max of 3
az aks nodepool update \
--resource-group $RG \
--cluster-name $CLUSTER_NAME \
--name $SYSTEMPOOL_NAME \
--enable-cluster-autoscaler \
--min-count 1 \
--max-count 3

# You can confirm the config was applied with the following command
az aks nodepool show -g $RG --cluster-name $CLUSTER_NAME -n $SYSTEMPOOL_NAME -o yaml |grep 'enableAutoScaling\|minCount\|maxCount'
enableAutoScaling: true
maxCount: 3
minCount: 1
```

Now lets configure the user pool:

```bash
# Based on the requirements, enable the cluster autoscaler on the user pool
# Requirments said min of 0 and max of 3
az aks nodepool update \
--resource-group $RG \
--cluster-name $CLUSTER_NAME \
--name $USERPOOL_NAME \
--enable-cluster-autoscaler \
--min-count 0 \
--max-count 3 
```

### Update Cluster Autoscale Profile

As mentioned above, you need to set the autoscale profile at the cluster level. 

```bash
# Update the cluster with the new autoscale profile settings
az aks update \
-g $RG \
-n $CLUSTER_NAME \
--cluster-autoscaler-profile "scan-interval=30s,scale-down-unneeded-time=1m,scale-down-delay-after-add=1m"

# You can verify your updates with the following command
az aks show -g $RG -n $CLUSTER_NAME -o yaml --query autoScalerProfile
balanceSimilarNodeGroups: 'false'
expander: random
maxEmptyBulkDelete: '10'
maxGracefulTerminationSec: '600'
maxNodeProvisionTime: 15m
maxTotalUnreadyPercentage: '45'
newPodScaleUpDelay: 0s
okTotalUnreadyCount: '3'
scaleDownDelayAfterAdd: 1m
scaleDownDelayAfterDelete: 10s
scaleDownDelayAfterFailure: 3m
scaleDownUnneededTime: 1m
scaleDownUnreadyTime: 20m
scaleDownUtilizationThreshold: '0.5'
scanInterval: 30s
skipNodesWithLocalStorage: 'false'
skipNodesWithSystemPods: 'true'
```

### Test the HPA

To test the HPA we need to create a deployment and a service with resource limits set, and then push the app pods beyond those limits. You can use any image for this, as long as you understand the resource usage characteristics so that you can appropriately set the HPA configuration. We've provided a sample app in the cheatsheet manifests.

> **NOTE**
> In a prior step you tainted the system pool to only run system pods. When you deploy this application it should go to the user pool. If you want to target a specific pools you'd need to make sure you look at Kubernetes [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) and [nodeselectors](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/). In our test that wont be needed.

Lets deploy the application and test the HPA:

```bash
# Apply the deployment, adjusting the relative path as needed
kubectl apply -f ../../manifests/workshop-cheatsheet/autoscale-test/deploy.yaml
deployment.apps/php-apache created
service/php-apache created

# Checkc out the deployment
```


### NEED TO FINISH


