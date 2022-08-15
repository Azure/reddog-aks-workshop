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

> **NOTE**
> The cluster is set up with egress lockdown, which means that you cant just put a public IP on a service, so you'll need to expose a private service via an [Azure Internal Load Balancer](https://docs.microsoft.com/en-us/azure/aks/internal-lb) and then test against the private IP.

```bash
# Apply the deployment, adjusting the relative path as needed
kubectl apply -f ../../manifests/workshop-cheatsheet/autoscale-test/deploy.yaml
deployment.apps/php-apache created
service/php-apache created

# Check out the deployment
kubectl get svc,pods
NAME                 TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
service/kubernetes   ClusterIP      10.245.0.1     <none>        443/TCP        47h
service/sample-app   LoadBalancer   10.245.0.144   10.140.0.5    80:32487/TCP   5m4s

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-698647c467-4vr7z   1/1     Running   0          22m
```

Next you should test that you can access the service. As mentioned above, you need to test against the private IP. There are many ways to do this. We'll take the simple appraoch of deploying an Ubuntu pod (Note: Make sure you've allowed Docker images and the Ubuntu Package Manager FQDNs through your egress firewall. Steps are at the end of the Egress Lockdown cheat sheet).

```bash
# Lets start and jump into an Ubuntu pod
kubectl run -it --rm ubuntu --image=ubuntu -- bash

# Run the following in the pod
apt update
apt install apache2-utils 

ab -V
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

# Run some load against the private IP of your sample-app service
ab -t 60 http://10.140.0.5/

# You should get output like the following
This is ApacheBench, Version 2.3 <$Revision: 1879490 $>
Copyright 1996 Adam Twiss, Zeus Technology Ltd, http://www.zeustech.net/
Licensed to The Apache Software Foundation, http://www.apache.org/

Benchmarking 10.140.0.5 (be patient)
Completed 5000 requests
Completed 10000 requests
Completed 15000 requests
Completed 20000 requests
Finished 23240 requests


Server Software:        Kestrel
Server Hostname:        10.140.0.5
Server Port:            80

Document Path:          /
Document Length:        3497 bytes

Concurrency Level:      1
Time taken for tests:   60.001 seconds
Complete requests:      23240
Failed requests:        0
Total transferred:      84337960 bytes
HTML transferred:       81270280 bytes
Requests per second:    387.33 [#/sec] (mean)
Time per request:       2.582 [ms] (mean)
Time per request:       2.582 [ms] (mean, across all concurrent requests)
Transfer rate:          1372.67 [Kbytes/sec] received

Connection Times (ms)
              min  mean[+/-sd] median   max
Connect:        1    1   0.8      1      16
Processing:     1    1   3.8      1      62
Waiting:        0    1   3.8      1      62
Total:          1    3   3.9      2      63

Percentage of the requests served within a certain time (ms)
  50%      2
  66%      2
  75%      2
  80%      2
  90%      3
  95%      4
  98%      9
  99%     15
 100%     63 (longest request)
```

Now lets deploy the Horizontal Pod Autoscaler and test it. It would probably be best to do this in a new terminal window, so you can keep your ApacheBench terminal up and running, if you used the steps above.

```bash
# Deploy the hpa config
kubectl apply -f ../../manifests/workshop-cheatsheet/autoscale-test/hpa.yaml

# In one terminal lets watch the status of the HPA and the pod count
watch kubectl get hpa,pods

# Back in the ApacheBench temrinal, run another test.
ab -t 60 http://10.140.0.5/

# After a few seconds you should start to see the HPA target metrics increase and the pod count go up

## BEFORE
NAME                                             REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/sample-app   Deployment/sample-app   0%/50%    1         10        1          36s

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-698647c467-pnw78   1/1     Running   0          6m21s
pod/ubuntu                        1/1     Running   0          10m

## AFTER
NAME                                             REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/sample-app   Deployment/sample-app   135%/50%   1         10        1          83s

NAME                              READY   STATUS    RESTARTS   AGE
pod/sample-app-698647c467-np2lj   1/1     Running   0          8s
pod/sample-app-698647c467-pnw78   1/1     Running   0          7m8s
pod/sample-app-698647c467-sgrcx   1/1     Running   0          8s
pod/ubuntu                        1/1     Running   0          10m

# After a bit you should also see the pods if you check 'top pod'
kubectl top pod
NAME                          CPU(cores)   MEMORY(bytes)   
sample-app-698647c467-np2lj   14m          21Mi            
sample-app-698647c467-pnw78   161m         61Mi            
sample-app-698647c467-sgrcx   15m          22Mi   
```

### Test the Cluster Autoscaler

The Cluster Autoscaler is looking for pods that are in a 'Pending' state because there arent enough nodes to handle the requested resources. To test it, we can tell the Kubernetes 
