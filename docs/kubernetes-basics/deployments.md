# Kubernetes Deployments

## Overview

Kubernetes Deployments provide a wrapper around Pods and Replica Sets. Replica Sets are the mechanism that track the number of instances of a given pod you want to run. For example, if you're running a web application you may want to scale the number of instances of that web application up or down based on demand. Additionally, Deployments provide the state tracking needed for performing rollback operations. More information can be found at the link below:

[Kubernetes Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)

### Deployment Creation

Lets start by creating a basic nginx container deployment with 3 replicas. This can be done both via an imperitive command and a manifest file.

<u>**Imperitive**</u>

```bash
# Create a deployment
kubectl create deployment nginx --image=nginx:1.23.4 --replicas=3

# Check the status of the Deployment, Replica Set and Pods. Notice that you can comma separate
kubectl get deployment,rs,pods

# Sample Output
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   3/3     3            3           27s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-7467c7b65c   3         3         3       27s

NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-7467c7b65c-6qltj   1/1     Running   0          27s
pod/nginx-7467c7b65c-6r46s   1/1     Running   0          27s
pod/nginx-7467c7b65c-6zhbt   1/1     Running   0          27s

# Now delete the deployment
# Notice that you can short hand deployment to deploy
kubectl delete deploy nginx
```

Now check out the deployment details.

```bash
# Describe the deployment and take some time to review the output
kubectl describe deployment nginx

# Sample Output
Name:                   nginx
Namespace:              lab
CreationTimestamp:      Fri, 19 May 2023 10:31:50 -0400
Labels:                 app=nginx
Annotations:            deployment.kubernetes.io/revision: 2
Selector:               app=nginx
Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=nginx
  Containers:
   nginx:
    Image:        nginx:1.24
    Port:         <none>
    Host Port:    <none>
    Environment:  <none>
    Mounts:       <none>
  Volumes:        <none>
Conditions:
  Type           Status  Reason
  ----           ------  ------
  Available      True    MinimumReplicasAvailable
  Progressing    True    NewReplicaSetAvailable
OldReplicaSets:  nginx-7467c7b65c (0/0 replicas created)
NewReplicaSet:   nginx-79697b9d48 (3/3 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  9m29s  deployment-controller  Scaled up replica set nginx-7467c7b65c to 3
  Normal  ScalingReplicaSet  9m18s  deployment-controller  Scaled up replica set nginx-79697b9d48 to 1
  Normal  ScalingReplicaSet  9m17s  deployment-controller  Scaled down replica set nginx-7467c7b65c to 2 from 3
  Normal  ScalingReplicaSet  9m17s  deployment-controller  Scaled up replica set nginx-79697b9d48 to 2 from 1
  Normal  ScalingReplicaSet  9m16s  deployment-controller  Scaled down replica set nginx-7467c7b65c to 1 from 2
  Normal  ScalingReplicaSet  9m16s  deployment-controller  Scaled up replica set nginx-79697b9d48 to 3 from 2
  Normal  ScalingReplicaSet  9m15s  deployment-controller  Scaled down replica set nginx-7467c7b65c to 0 from 1
```

<u>**Declarative**</u>

```bash
# First lets generate a manifest file
kubectl create deployment nginx --image=nginx:1.23.4 --replicas=3 --dry-run=client -o yaml>nginx-deployment.yaml
```

The file created will look like the following. Again, auto-generated manifests will have some extra details you can remove, like 'status', 'resources' and the timestamps. I've already removed those in the sample below.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:1.23.4
        name: nginx
```

```bash
# Deploy the manifest
kubectl apply -f nginx-deployment.yaml

# Check the status of the Deployment, Replica Set and Pods. Notice that you can comma separate
kubectl get deployment,rs,pods

# Sample Output
kubectl get deployment,rs,pods

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   3/3     3            3           24s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-7467c7b65c   3         3         3       24s

NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-7467c7b65c-frx56   1/1     Running   0          24s
pod/nginx-7467c7b65c-rlwkt   1/1     Running   0          24s
pod/nginx-7467c7b65c-tdvfd   1/1     Running   0          24s
```

### Deployment Rollback

Now that we have a deployment, lets make a change and then roll that change back. In this case we'll just update the image tag. For this task it would be good to open a second terminal window and run 'watch kubectl get pods' to see the behavior as new deployments are created and updated. You will see how Kubernetes ensures pods remain running curing the update.

```bash
# Update the image for the deployment
kubectl set image deployment/nginx nginx=nginx:1.24

# Manually provide the change annotation
kubectl annotate deployment/nginx kubernetes.io/change-cause="image updated to 1.24"

# Check the rollout status
kubectl rollout status deployment/nginx

# Sample Output..if you're fast enough
Waiting for deployment "nginx" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx" rollout to finish: 1 old replicas are pending termination...
deployment "nginx" successfully rolled out

# Check the container image version on your pods
# Get your pods
kubectl get pods --show-labels

# You can describe a pod
kubectl describe pod <pod name>

# Alternatively, you can use a pod label to get all pods with the label and then use jsonpath to get the specific value
kubectl get pod -l app=nginx -o jsonpath='{.items[0].spec.containers[0].image}'

# Sample Output
nginx:1.24
```

Now that the deployment has been updated, lets assume there's an issue and we need to roll back.

```bash
# Show the rollout history
kubectl rollout history deployment/nginx

# Sample Output
REVISION  CHANGE-CAUSE
1         <none>
2         image updated to 1.24

# Roll back to revision 1
kubectl rollout undo deployment/nginx --to-revision=1

# Sample Output
REVISION  CHANGE-CAUSE
2         image updated to 1.24
3         <none>

# Check the pod image has rolled back to 1.23.4
kubectl get pod -l app=nginx -o jsonpath='{.items[0].spec.containers[0].image}'
```

Notice in the above that a roll back technically is a new revision in revision tracking.

### Replica Sets and Scaling

We've already see the concept of 'replicas' in the above deployment. The replica count is managed by a Kubernetes [Replica Set](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/). We can use the replica set to drive the number of instances of a pod up or down. The replica set is also used by the [Horizontal Pod Autoscaler (HPA)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) to automatically drive the pod count up or down based on configured metrics. Additionally, the [Kubernetes Event Driven Autoscaler (KEDA)](https://keda.sh/) expands on the HPA to enable scaling on an array of source metrics. 

We have a separate lab on the HPA and Cluster Autoscaler which you can get to from the link below. For this lab we'll focus on the simple act of scaling a replica set up and down.

* [Autoscaling Setup](https://github.com/Azure/reddog-aks-workshop/blob/main/docs/cheatsheets/008-autoscaling-setup-cheatsheet.md)

You should still have a deployment running with 3 replicas. Let's scale that deployment up and down.

```bash
# Check the deployment
kubectl get deployment

# Sample Output
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   3/3     3            3           30m

# You can also check the replica set directly
kubectl get rs

# Sample Output
NAME               DESIRED   CURRENT   READY   AGE
nginx-7467c7b65c   3         3         3       50s
nginx-79697b9d48   0         0         0       41s
```

Notice in the above that you have an extra replica set with no pods. That's part of the rollout/rollback mechanism.

```bash
# Scale up to 10 pods
kubectl scale deployment nginx --replicas=10

# Check the deployment, replica set and pods
kubectl get deploy,rs,pods

# Sample Output
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   10/10   10           10          2m56s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-7467c7b65c   10        10        10      2m56s
replicaset.apps/nginx-79697b9d48   0         0         0       2m47s

NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-7467c7b65c-4wj6q   1/1     Running   0          47s
pod/nginx-7467c7b65c-7qcxv   1/1     Running   0          2m11s
pod/nginx-7467c7b65c-f667c   1/1     Running   0          47s
pod/nginx-7467c7b65c-fnwmd   1/1     Running   0          47s
pod/nginx-7467c7b65c-gtzc4   1/1     Running   0          47s
pod/nginx-7467c7b65c-lrhkc   1/1     Running   0          47s
pod/nginx-7467c7b65c-ph2md   1/1     Running   0          2m13s
pod/nginx-7467c7b65c-rhptj   1/1     Running   0          2m10s
pod/nginx-7467c7b65c-rjws7   1/1     Running   0          47s
pod/nginx-7467c7b65c-vsjzd   1/1     Running   0          47s

# Now scale down to 1 pod
kubectl scale deployment nginx --replicas=1

# Check the deployment, replica set and pods
kubectl get deploy,rs,pods

# Sample Output
NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   1/1     1            1           3m52s

NAME                               DESIRED   CURRENT   READY   AGE
replicaset.apps/nginx-7467c7b65c   1         1         1       3m52s
replicaset.apps/nginx-79697b9d48   0         0         0       3m43s

NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-7467c7b65c-rhptj   1/1     Running   0          3m6s
```

### Cleanup

```bash
# You can now delete your deployment
kubectl delete deploy nginx
```

## Conclusion

You should now have a basic undersatnding of the use of deployments and replica sets and their ability to maintain rollout history and execute a roll back. For more details you can read the following docs.

* [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
* [Replica Sets](https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/)
* [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
* [JSONPath Usage](https://kubernetes.io/docs/reference/kubectl/jsonpath/)

## Next Lab:

[Kubernetes Daemonsets](./daemonsets.md)