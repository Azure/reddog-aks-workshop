## Cluster Upgrade Cheatsheet

In cluster upgrade, you were given the following requirements:

* Initial testing should use a manual upgrade process
* The UI running pod count should be increased to 2
* The UI pod count should never go below 1 during an upgrade
* Day 1 (simulated): Due to a critical OS level CVE you've been asked to upgrade the system pool **NODE IMAGE ONLY**
* Day 2 (simulated): Due to a critical Kubernetes level CVI you've been asked to upgrade the control plane and the system pool Kubernetes version to the next incremental version (major or minor)
* Day 3 (simulated): To take advantage of some new Kubernetes features you've been asked to upgrade the user pool Kubernetes version to the next incremental version (major or minor)
  
You were asked to complete the following tasks:

1. Increase the Red Dog UI deployment replica count to 2
2. Deploy the necessary config to ensure the UI pod count never dips below 1 pod
3. Check the available upgrade versions for Kubernetes and Node Image
4. Upgrade the system pool node image
5. Upgrade the AKS control plane and system pool Kubernetes version
6. Uprade the user pool Kubernetes version
   
    **Bonus Tasks:**
7. Enable Automatic Uprades to the 'patch' channel and set a Planned Maintenance Window (preview) for Saturdays at 1am


### Increase the Red Dog UI deployment replica count to 2

```bash
# List all deployments in reddog
kubectl get deployments -n reddog

# Output
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
accounting-service   1/1     1            1           98m
loyalty-service      1/1     1            1           98m
make-line-service    1/1     1            1           98m
order-service        1/1     1            1           98m
ui                   1/1     1            1           98m
virtual-customers    1/1     1            1           98m
virtual-worker       1/1     1            1           98m

# Scale up the UI deployment to 2 replicas
kubectl scale deployment ui -n reddog --replicas=2

# Check the replica count again
kubectl get deployments -n reddog

# Output
NAME                 READY   UP-TO-DATE   AVAILABLE   AGE
accounting-service   1/1     1            1           99m
loyalty-service      1/1     1            1           99m
make-line-service    1/1     1            1           99m
order-service        1/1     1            1           99m
ui                   2/2     2            2           99m
virtual-customers    1/1     1            1           99m
virtual-worker       1/1     1            1           99m

# Or you can check via the replicaset directly
kubectl get replicaset -n reddog

# Output
NAME                            DESIRED   CURRENT   READY   AGE
accounting-service-6dd7d846c5   1         1         1       99m
loyalty-service-5456c5859       1         1         1       99m
make-line-service-5f5c89bc8c    1         1         1       99m
order-service-595b7d5fdc        1         1         1       99m
ui-85f94c974                    2         2         2       99m
virtual-customers-d8b7bb687     1         1         1       99m
virtual-worker-7688f55746       1         1         1       99m
```


### Deploy the necessary config to ensure the UI pod count never dips below 1 pod

Kubernetes provides [Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/) as a mechanism to ensure a minimum pod count during [Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/).

We need to ensure that there is minimum of one UI pod, so the PodDisruptionBudget config would look like the following:

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: ui-pdb
spec:
  minAvailable: 1
  selector:
    matchLabels:
      app: ui
```

Deply the pdb.

```bash
# Apply the manifest
kubectl apply -f ../../manifests/workshop-cheatsheet/upgrade/pod-disruption-budget.yaml

# Check the pdb
kubectl get pdb

# Output
NAME     MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
ui-pdb   1               N/A               1                     23s
```

### Check the available upgrade versions for Kubernetes and Node Image

```bash
# To check at the cluster level
az aks get-upgrades -g $RG -n $CLUSTER_NAME

# Output
Name     ResourceGroup           MasterVersion    Upgrades
-------  ----------------------  ---------------  --------------
default  RedDogAKSWorkshop_test  1.22.11          1.23.5, 1.23.8

# Get the current system pool node image version
az aks nodepool show -g $RG --cluster-name $CLUSTER_NAME --nodepool-name systempool -o tsv --query nodeImageVersion
AKSUbuntu-1804gen2containerd-2022.07.28

# Get the latest system pool node image version
az aks nodepool get-upgrades -g $RG --cluster-name $CLUSTER_NAME --nodepool-name systempool -o tsv --query latestNodeImageVersion
AKSUbuntu-1804gen2containerd-2022.07.28
```

### Upgrade the system pool node image

In the above check you may have found that you're already running the latest node image version. If so, no action is needed. If not, you can upgrade as follows:

```bash
# Run a node image upgrad eon the system pool
az aks nodepool upgrade \
--resource-group $RG \
--cluster-name $CLUSTER_NAME \
--name systempool \
--node-image-only 
```

### Upgrade the system pool Kubernetes version

To upgrade the kubernetes version, the command is the same as above without the --node-image-only tag.

```bash
# Set your environment variabls
RG=RedDogAKSWorkshop
CLUSTER_NAME=reddog-griffith

# We can again check available versions
az aks get-upgrades -g $RG -n $CLUSTER_NAME

# Output
Name     ResourceGroup           MasterVersion    Upgrades
-------  ----------------------  ---------------  --------------
default  RedDogAKSWorkshop_test  1.22.11          1.23.5, 1.23.8

# Upgrade the control plane
# NOTE: You cannot upgrade a nodepool before the control plane has been upgrade
az aks upgrade \
-g $RG \
-n $CLUSTER_NAME \
--control-plane-only \
--kubernetes-version 1.23.5

# In one terminal (optionally) you can watch the system pool nodes as they get upgrade
watch kubectl get nodes -l agentpool=systempool

# In another terminal, start the upgrade
az aks nodepool upgrade \
--resource-group $RG \
--cluster-name $CLUSTER_NAME \
--name systempool \
--kubernetes-version 1.23.5

# Sample output. A node is added with the new version and the old node immediately blocks
# schduling (aka cordoned)
NAME                                 STATUS                     ROLES    AGE   VERSION
aks-systempool-19117480-vmss000000   Ready,SchedulingDisabled   agent    20h   v1.22.11
aks-systempool-19117480-vmss000001   Ready                      agent    20h   v1.22.11
aks-systempool-19117480-vmss000002   Ready                      agent    20h   v1.22.11
aks-systempool-19117480-vmss000003   NotReady                   <none>   11s   v1.23.5

# When the new node is ready, the pods on the old node will drain to the new node (this is where pdb becomes critical)
NAME                                 STATUS                     ROLES   AGE   VERSION
aks-systempool-19117480-vmss000000   Ready,SchedulingDisabled   agent   20h   v1.22.11
aks-systempool-19117480-vmss000001   Ready                      agent   20h   v1.22.11
aks-systempool-19117480-vmss000002   Ready                      agent   20h   v1.22.11
aks-systempool-19117480-vmss000003   Ready                      agent   33s   v1.23.5

# Once all pods are drained from the node and moved to the new node, the node is removed
NAME                                 STATUS   ROLES   AGE   VERSION
aks-systempool-19117480-vmss000001   Ready    agent   20h   v1.22.11
aks-systempool-19117480-vmss000002   Ready    agent   20h   v1.22.11
aks-systempool-19117480-vmss000003   Ready    agent   68s   v1.23.5

# Notice that the node ending in zero is now gone and replaced with the node ending in 3
# This process will repeat until all nodes are upgraded and eventually node 3 will shift its name
# back so the original node naming is maintained.
NAME                                 STATUS   ROLES   AGE     VERSION
aks-systempool-19117480-vmss000000   Ready    agent   9m29s   v1.23.5
aks-systempool-19117480-vmss000001   Ready    agent   6m12s   v1.23.5
aks-systempool-19117480-vmss000002   Ready    agent   2m33s   v1.23.5
```

### Uprade the user pool Kubernetes version

You need to repeat the above steps, but this time, rather than watching the node list you should watch the pod list and see how your pod disruption budget ensures you have at least 1 UI pod running at all times.

```bash
# In one terminal watch the reddog pods
watch kubectl get pods -n reddog -o wide
# Output
# Notice your 2 ui pods
NAME                                  READY   STATUS    RESTARTS       AGE    IP            NODE                               NOMINATED NODE   READINESS GATES
accounting-service-6dd7d846c5-cgfsr   2/2     Running   0              152m   10.244.3.13   aks-userpool-28387458-vmss000000   <none>           <none>
loyalty-service-5456c5859-mm5sz       2/2     Running   0              154m   10.244.3.10   aks-userpool-28387458-vmss000000   <none>           <none>
make-line-service-5f5c89bc8c-9q8n4    2/2     Running   0              152m   10.244.4.16   aks-userpool-28387458-vmss000001   <none>           <none>
order-service-595b7d5fdc-7fmvx        2/2     Running   0              154m   10.244.3.11   aks-userpool-28387458-vmss000000   <none>           <none>
ui-85f94c974-5qfn9                    2/2     Running   0              55m    10.244.5.16   aks-userpool-28387458-vmss000002   <none>           <none>
ui-85f94c974-7sjc8                    2/2     Running   0              152m   10.244.3.14   aks-userpool-28387458-vmss000000   <none>           <none>
virtual-customers-d8b7bb687-jffvv     2/2     Running   0              154m   10.244.4.14   aks-userpool-28387458-vmss000001   <none>           <none>
virtual-worker-7688f55746-hh22h       2/2     Running   0              154m   10.244.3.12   aks-userpool-28387458-vmss000000   <none>           <none>

# In another terminal, start the upgrade
az aks nodepool upgrade \
--resource-group $RG \
--cluster-name $CLUSTER_NAME \
--name userpool \
--kubernetes-version 1.23.5

# The node upgrades follow the same process as above, but eventually you'll see one, and only one, of the UI pods temrinated
# so that it can move to the new node.
NAME                                  READY   STATUS              RESTARTS       AGE    IP            NODE                               NOMINATED NODE   READINESS GA
TES
accounting-service-6dd7d846c5-cgfsr   2/2     Terminating         1 (153m ago)   153m   10.244.3.13   aks-userpool-28387458-vmss000000   <none>           <none>
accounting-service-6dd7d846c5-tp85r   0/2     Completed           0              5s     10.244.5.19   aks-userpool-28387458-vmss000002   <none>           <none>
loyalty-service-5456c5859-25tvg       0/2     ContainerCreating   0              5s     <none>        aks-userpool-28387458-vmss000002   <none>           <none>
loyalty-service-5456c5859-mm5sz       2/2     Terminating         0              155m   10.244.3.10   aks-userpool-28387458-vmss000000   <none>           <none>
make-line-service-5f5c89bc8c-9q8n4    2/2     Running             0              153m   10.244.4.16   aks-userpool-28387458-vmss000001   <none>           <none>
order-service-595b7d5fdc-7fmvx        2/2     Terminating         0              155m   10.244.3.11   aks-userpool-28387458-vmss000000   <none>           <none>
order-service-595b7d5fdc-j7kgk        0/2     ContainerCreating   0              5s     <none>        aks-userpool-28387458-vmss000002   <none>           <none>
ui-85f94c974-5qfn9                    2/2     Running             0              56m    10.244.5.16   aks-userpool-28387458-vmss000002   <none>           <none>
ui-85f94c974-7sjc8                    2/2     Terminating         0              153m   10.244.3.14   aks-userpool-28387458-vmss000000   <none>           <none>
ui-85f94c974-c8gkz                    1/2     Running             0              5s     10.244.4.17   aks-userpool-28387458-vmss000001   <none>           <none>
virtual-customers-d8b7bb687-jffvv     2/2     Running             0              155m   10.244.4.14   aks-userpool-28387458-vmss000001   <none>           <none>
virtual-worker-7688f55746-hh22h       2/2     Terminating         0              155m   10.244.3.12   aks-userpool-28387458-vmss000000   <none>           <none>
virtual-worker-7688f55746-wr69p       0/2     ContainerCreating   0              5s     <none>        aks-userpool-28387458-vmss000002   <none>           <none>

# In the above, notice all the single instance terminations and think about the impact that could have on your running application
# It would eventually make sense to increase all of their replica counts and implement PodDisruptionBudgets for those as well
# but thats out of scope for this excecise. 

NAME                                  READY   STATUS    RESTARTS      AGE    IP            NODE                               NOMINATED NODE   READINESS GATES
accounting-service-6dd7d846c5-tp85r   2/2     Running   5 (29s ago)   65s    10.244.5.19   aks-userpool-28387458-vmss000002   <none>           <none>
loyalty-service-5456c5859-25tvg       2/2     Running   0             65s    10.244.5.21   aks-userpool-28387458-vmss000002   <none>           <none>
make-line-service-5f5c89bc8c-9q8n4    2/2     Running   0             154m   10.244.4.16   aks-userpool-28387458-vmss000001   <none>           <none>
order-service-595b7d5fdc-j7kgk        2/2     Running   0             65s    10.244.5.22   aks-userpool-28387458-vmss000002   <none>           <none>
ui-85f94c974-5qfn9                    2/2     Running   0             57m    10.244.5.16   aks-userpool-28387458-vmss000002   <none>           <none>
ui-85f94c974-c8gkz                    2/2     Running   0             65s    10.244.4.17   aks-userpool-28387458-vmss000001   <none>           <none>
virtual-customers-d8b7bb687-jffvv     2/2     Running   0             156m   10.244.4.14   aks-userpool-28387458-vmss000001   <none>           <none>
virtual-worker-7688f55746-wr69p       2/2     Running   0             65s    10.244.5.20   aks-userpool-28387458-vmss000002   <none>           <none>

# You should have found that this upgrade was much faster than the systempool upgrade, because we had far fewer pods, and almost no pod disruption budgets to be concerned with, which inherently slow down upgrades.
```

### BONUS: Enable Automatic Uprades to the 'patch' channel and set a Planned Maintenance Window

While the above process is actually pretty easy and could be automated through a ticketing system without much effort, for lower environments (dev/test) you may consider letting AKS manage the version upgrades for you. You can also specify the upgrade window.

```bash
# Check the current auto upgrade profile
az aks show -g $RG -n $CLUSTER_NAME -o tsv --query autoUpgradeProfile
# Output should be null

# Enable auto upgrades to the 'patch' channel
az aks update \
--resource-group $RG \
--name $CLUSTER_NAME \
--auto-upgrade-channel patch

# Check the auto upgrade profile again
az aks show -g $RG -n $CLUSTER_NAME -o tsv --query autoUpgradeProfile
patch

# Create the planned maintenance configuration for Saturdays at 1am
az aks maintenanceconfiguration add \
-g $RG \
--cluster-name $CLUSTER_NAME \
--name default \
--weekday Saturday  \
--start-hour 1

# Show the current maintenance window configuration
az aks maintenanceconfiguration show \
-g $RG \
--cluster-name $CLUSTER_NAME \
--name default \
-o yaml

# Output
resource_group_name: RedDogAKSWorkshop_test, cluster_name: reddog-griffith, config_name: default 
id: /subscriptions/<.....>/resourceGroups/RedDogAKSWorkshop_test/providers/Microsoft.ContainerService/managedClusters/reddog-griffith/maintenanceConfigurations/default
name: default
notAllowedTime: null
resourceGroup: RedDogAKSWorkshop_test
systemData: null
timeInWeek:
- day: Saturday
  hourSlots:
  - 1
type: null
```

