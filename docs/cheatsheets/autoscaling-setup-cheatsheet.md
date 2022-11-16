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
aks nodepool list -g $RG --cluster-name $CLUSTER_NAME
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

> **NOTES**
>
> * In a prior step you tainted the system pool to only run system pods. When you deploy this application it should go to the user pool. If you want to target a specific pools you'd need to make sure you look at Kubernetes [tolerations](https://kubernetes.io/docs/concepts/scheduling-eviction/taint-and-toleration/) and [nodeselectors](https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/). In our test that wont be needed.
> * If the cluster is set up with egress lockdown, you cant just put a public IP on a service so you'll need to expose a private service via an [Azure Internal Load Balancer](https://docs.microsoft.com/en-us/azure/aks/internal-lb) and then test against the private IP.


```bash
# Apply the deployment, adjusting the relative path as needed
kubectl apply -f ../../manifests/workshop-cheatsheet/autoscale-test/deploy.yaml
deployment.apps/sample-app created
service/sample-app created

# Check out the deployment
kubectl get svc,pods
NAME                 TYPE           CLUSTER-IP    EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP      10.245.0.1    <none>        443/TCP        6d19h
service/sample-app   LoadBalancer   10.245.0.45   10.140.0.5    80:30931/TCP   3m22s

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-698647c467-tv9l8   1/1     Running   0          3m22s
```

Next you should test that you can access the service. As mentioned above, you need to test against the private IP. There are many ways to do this. We'll take the simple approach of deploying an Ubuntu pod (Note: Make sure you've allowed Docker images and the Ubuntu Package Manager FQDNs through your egress firewall. Steps are at the end of the Egress Lockdown cheat sheet).

```bash
# Lets start and jump into an Ubuntu pod
kubectl run -it --rm ubuntu --image=ubuntu -- bash

# Run the following in the pod
apt update
apt install -y apache2-utils 

ab -V
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

# Run some load against the private IP of your sample-app service
# Checkout the ab docs, or run 'ab -h', to understand the below command flags
ab -t 240 -c 10 -n 100000 http://10.140.0.5/

# You should get output like the following
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 10.140.0.5 (be patient)
Completed 10000 requests
Completed 20000 requests
Completed 30000 requests
Completed 40000 requests
Completed 50000 requests
Completed 60000 requests
Completed 70000 requests
Completed 80000 requests
Completed 90000 requests
Completed 100000 requests
Finished 100000 requests


Server Software:        Kestrel
Server Hostname:        10.140.0.5
Server Port:            80

Document Path:          /
Document Length:        3497 bytes

Concurrency Level:      10
Time taken for tests:   99.693 seconds
Complete requests:      100000
Failed requests:        24946
   (Connect: 0, Receive: 0, Length: 24946, Exceptions: 0)
Total transferred:      362875054 bytes
HTML transferred:       349675054 bytes
Requests per second:    1003.08 [#/sec] (mean)
Time per request:       9.969 [ms] (mean)
Time per request:       0.997 [ms] (mean, across all concurrent requests)
Transfer rate:          3554.62 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    3   2.5      2      36
Processing:     1    7   7.1      6     365
Waiting:        0    6   6.8      4     363
Total:          1   10   7.5      8     366

Percentage of the requests served within a certain time (ms)
  50%      8
  66%     10
  75%     12
  80%     13
  90%     17
  95%     21
  98%     30
  99%     37
 100%    366 (longest request)
root@ubuntu:/# ab -t 240 -c 10 -n 100000 http://10.140.0.5/
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 10.140.0.5 (be patient)
Completed 10000 requests
Completed 20000 requests
Completed 30000 requests
Completed 40000 requests
Completed 50000 requests
Completed 60000 requests
Completed 70000 requests
Completed 80000 requests
Completed 90000 requests
Completed 100000 requests
Finished 100000 requests


Server Software:        Kestrel
Server Hostname:        10.140.0.5
Server Port:            80

Document Path:          /
Document Length:        3498 bytes

Concurrency Level:      10
Time taken for tests:   118.865 seconds
Complete requests:      100000
Failed requests:        0
Total transferred:      363000000 bytes
HTML transferred:       349800000 bytes
Requests per second:    841.29 [#/sec] (mean)
Time per request:       11.886 [ms] (mean)
Time per request:       1.189 [ms] (mean, across all concurrent requests)
Transfer rate:          2982.31 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        0    2   3.0      1      93
Processing:     1   10   8.4      7     209
Waiting:        0    9   8.1      7     194
Total:          1   12   8.9      9     209

Percentage of the requests served within a certain time (ms)
  50%      9
  66%     11
  75%     13
  80%     14
  90%     19
  95%     34
  98%     44
  99%     47
 100%    209 (longest request)
```

Now lets deploy the Horizontal Pod Autoscaler and test it. It would probably be best to do this in a new terminal window, so you can keep your ApacheBench terminal up and running, if you used the steps above.

```bash
# Deploy the hpa config
kubectl apply -f ../../manifests/workshop-cheatsheet/autoscale-test/hpa.yaml

# In one terminal lets watch the status of the HPA and the pod count
watch kubectl get hpa,pods,nodes

# Back in the ApacheBench terminal, run another test.
ab -t 240 http://10.140.0.5/

# After a few seconds you should start to see the HPA target metrics increase and the pod count go up

## BEFORE
NAME                                             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/sample-app   Deployment/sample-app   0%/20%    1         2         1          36s

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-698647c467-pnw78   1/1     Running   0          6m21s
pod/ubuntu                        1/1     Running   0          10m

## AFTER
NAME                                             REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/sample-app   Deployment/sample-app   135%/20%   1         2         2          83s

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-698647c467-np2lj   1/1     Running   0          8s
pod/sample-app-698647c467-pnw78   1/1     Running   0          7m8s
pod/ubuntu                        1/1     Running   0          10m

# After a bit you should also see the pods if you check 'top pod'
kubectl top pod
NAME                          CPU(cores)   MEMORY(bytes)   
sample-app-698647c467-np2lj   14m          21Mi            
sample-app-698647c467-pnw78   161m         61Mi            
```

### Test the Cluster Autoscaler

The Cluster Autoscaler is looking for pods that are in a 'Pending' state because there aren't enough nodes to handle the requested resources. To test it, we can just play around with the cpu request size and the max replicas in the HPA. Lets set the request size to 1000m (1 core) and the max pods to 5. This should cause the HPA to create up to 5 pods under load, and each pod will require 1 core, so we'll quickly spill over the current single node.

```bash
# Make the above mentioned changes in your deploy.yaml and hpa.yaml files and redeploy.
kubectl apply -f ../../manifests/workshop-cheatsheet/autoscale-test/deploy.yaml
kubectl apply -f ../../manifests/workshop-cheatsheet/autoscale-test/hpa.yaml
# Check the hpa, pods and nodes
kubectl get hpa,pods,nodes

# Sample output
NAME                                             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/sample-app   Deployment/sample-app   0%/20%    1         5         1          8m7s

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-6d4dfc87ff-prs4m   1/1     Running   0          16s
pod/ubuntu                        1/1     Running   0          65m

NAME                                      STATUS   ROLES   AGE     VERSION
node/aks-systempool-49954760-vmss000000   Ready    agent   6d21h   v1.22.11
node/aks-userpool-23312598-vmss000003     Ready    agent   67m     v1.22.11
```

Now run the test again

```bash
# In your apachebench terminal
ab -t 240 -c 10 -n 100000 http://10.140.0.5/

# In your other terminal
watch kubectl get hpa,pods,nodes

# Before we start
NAME                                             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/sample-app   Deployment/sample-app   0%/20%    1         5         5          11m

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-6d4dfc87ff-prs4m   1/1     Running   0          3m33s
pod/ubuntu                        1/1     Running   0          68m

NAME                                      STATUS   ROLES   AGE     VERSION
node/aks-systempool-49954760-vmss000000   Ready    agent   6d21h   v1.22.11
node/aks-userpool-23312598-vmss000003     Ready    agent   70m     v1.22.11

# As you run the load test
NAME                                             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/sample-app   Deployment/sample-app   77%/20%   1         5         1          12m

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-6d4dfc87ff-ldw4n   0/1     Pending   0          9s
pod/sample-app-6d4dfc87ff-m6zq6   0/1     Pending   0          9s
pod/sample-app-6d4dfc87ff-prs4m   1/1     Running   0          4m50s
pod/sample-app-6d4dfc87ff-pzb2t   0/1     Pending   0          9s
pod/ubuntu                        1/1     Running   0          69m

NAME                                      STATUS     ROLES    AGE     VERSION
node/aks-systempool-49954760-vmss000000   Ready      agent    6d21h   v1.22.11
node/aks-userpool-23312598-vmss000003     Ready      agent    71m     v1.22.11
node/aks-userpool-23312598-vmss00000a     NotReady   <none>   9s      v1.22.11
node/aks-userpool-23312598-vmss00000b     NotReady   <none>   2s      v1.22.11
```

### Tuning

As you probably saw above, CPU based scaling can sometimes be a bit slow. There are a lot of factors that come into play that you can tune. As you saw above, there's the autoscaler profile settings that can be adjusted. You can also adjust the CPU and Memory thresholds. To improve the time taken to add a node to the cluster, you can look at the [autoscale mode](https://docs.microsoft.com/en-us/azure/aks/scale-down-mode), which will let you scale down by stopping but not deleting nodes (aka deallocation mode). This way a new node wont need to be provisioned, but rather an existing deallocated node just needs to be started.
