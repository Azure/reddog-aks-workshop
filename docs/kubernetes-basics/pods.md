# Kubernetes Namespaces

## Overview

In Kubernetes, pods provide the smallest unit of deployment for a container. Pods allow multiple closely related containers to be deployed together under a shared storage and network boundary. More information can be found at the link below.

[Kubernetes Namespaces](https://kubernetes.io/docs/concepts/workloads/pods/)

### Pod Creation and Deletion

As with [Namespaces](./namespaces.md), we'll run through both the impertive and declaritive methods.
'=
>**Note:** If you're coming to this lab from the namespaces lab, you may still have your context set to default to the 'lab' namespace. We wont be using the namespace parameter in this lab, so it will default to the namespace listed in your context. You can check with 'kubectl config get-contexts'

<u>**Imperitive**</u>

```bash
# Create a simple pod
kubectl run nginx --image=nginx

# Check for the pod
kubectl get pods

# Sample Output
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          10s
```

Do a describe on the pod and take some time to read through and understand the output from the describe command. At this point you likely wont fully understand all the details, but you should be able to see the following:

* Pod Name
* Pod Namespace
* Node the pod is running on
* Pod Status
* Pod IP in the cluster
* List of containers in the pod (currently only 1 container)
* Container Image ID
* Container Ports
* Events related to the pod startup
  

```bash
# Look at the pod details
kubectl describe pod nginx

# Sample Output
Name:             nginx
Namespace:        lab
Priority:         0
Service Account:  default
Node:             aks-nodepool1-40230841-vmss000000/10.224.0.5
Start Time:       Wed, 17 May 2023 14:16:39 -0400
Labels:           run=nginx
Annotations:      <none>
Status:           Running
IP:               10.244.1.4
IPs:
  IP:  10.244.1.4
Containers:
  nginx:
    Container ID:   containerd://f7635fcda1180c1f72699fbbf2bf4f1d9e0dc3d2c71c1275c71b0024d6e65180
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:480868e8c8c797794257e2abd88d0f9a8809b2fe956cbfbc05dcc0bca1f7cd43
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Wed, 17 May 2023 14:16:44 -0400
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-kswsp (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  kube-api-access-kswsp:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    ConfigMapOptional:       <nil>
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  67s   default-scheduler  Successfully assigned lab/nginx to aks-nodepool1-40230841-vmss000000
  Normal  Pulling    66s   kubelet            Pulling image "nginx"
  Normal  Pulled     62s   kubelet            Successfully pulled image "nginx" in 4.358345527s (4.35836754s including waiting)
  Normal  Created    62s   kubelet            Created container nginx
  Normal  Started    62s   kubelet            Started container nginx
```

Delete the pod and we will recreate with the Declaritive approach.

```bash
kubectl delete pod nginx
```

<u>**Declaritive**</u>

First we need a Kubernetes manifest file for the pod. We could find an example online, but kubectl will also help us create one via the 'dry-run' flag. We can use that to output a manifest to a file of our choosing.

```bash
# Create a pod manifest file
kubectl run nginx --image=nginx --dry-run=client -o yaml > nginxpod.yaml
```

Open the nginxpod.yaml file and take some time to understand it. There are some details in there that arent relevant and can technically be removed. For example, we havent deployed this yet, so the 'status' section is irrelevant. We'll leave these details for now.

```bash
# Deploy the pod
kubectl apply -f nginxpod.yaml

# Sample Output
pod/nginx created

# Check for the pod
kubectl get pods

# Sample Output
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          10s
```

Before we move on, delete the pod.

```bash
# Delete the pod
kubectl delete pod nginx 
```

## Basic Sidecar Example

The fact that all containers in a pod share common networking and storage opens up the opportunity for you to do some cool things. In particular, you can isolate certain common needs into a container that can then be shared by multiple pods and multiple applications. For example, maybe you have a logging tool and you don't want to build that into your application container. This is also how things like [Service Mesh](https://linkerd.io/what-is-a-service-mesh/) work.

Lets run a very basic example of a sidecar. First, create a file with the following called sidecar-demo.yaml.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: sidecar-demo
  name: sidecar-demo
spec:
  containers:
  - image: ubuntu
    name: application-server
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do date>>/tmp/log.txt; sleep 5; done;" ]
```

The above pod runs an ubuntu container that writes the current datetime out to a file every 5 seconds. Lets test.

```bash
# Deploy the pod
kubectl apply -f sidecar-demo.yaml

# Check the pod logs. We shouldnt see any output
kubectl logs sidecar-demo

# Check the log.txt file
kubectl exec sidecar-demo -- cat /tmp/log.txt

# Sample Output
Wed May 17 18:55:58 UTC 2023
Wed May 17 18:56:03 UTC 2023
Wed May 17 18:56:08 UTC 2023
Wed May 17 18:56:13 UTC 2023
```

That looks good, but we didnt have any output logs visible to Kubernetes. Thats because Kubernetes is looking for stdout and stderr. We can fix that easily by adding a container and a shared folder between the two containers. Then we can have the second container just [tail](https://manpages.ubuntu.com/manpages/bionic/man1/tail.1.html) the logs from the first.

Edit the manifest file and update to include the second container and shared volume. Take some time to look at the manifest file t below to understand what it's doing.

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: sidecar-demo
  name: sidecar-demo
spec:
  containers:
  - image: ubuntu
    name: application-server
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "while true; do date>>/tmp/log.txt; sleep 5; done;" ]
    volumeMounts:
    - mountPath: /tmp
      name: log-volume    
  - image: ubuntu
    name: logging-agent
    command: [ "/bin/bash", "-c", "--" ]
    args: [ "tail -f /tmp/log.txt" ]
    volumeMounts:
    - mountPath: /tmp
      name: log-volume
  volumes:
  - name: log-volume
    emptyDir:
      sizeLimit: 500Mi

```

Deploy the updated manifest.

```bash
# First we need to delete the first deployment.
kubectl delete -f sidecar-demo.yaml

# Now re-apply
kubectl apply -f sidecar-demo.yaml

# Check the pod deployed, and notice the container count is 2/2
kubectl get pods

# Sample Output
NAME           READY   STATUS    RESTARTS   AGE
sidecar-demo   2/2     Running   0          8s
```

Now lets check the logs.

```bash
# Get the logs by passing in the target container
kubectl logs sidecar-demo -c logging-agent

# Sample Output
Wed May 17 19:03:41 UTC 2023
Wed May 17 19:03:46 UTC 2023
Wed May 17 19:03:51 UTC 2023
```

Congratulations, you've created your first Kubernetes sidecar container!

## Debugging

You've already seen in the above steps that we can get the stdout and stderr details from a pod and it's containers. You also saw that we have the ability to run commands within the container. Lets look at those commands again.

```bash
# Get a pod name
kubectl get pods

# Output
NAME           READY   STATUS    RESTARTS   AGE
sidecar-demo   2/2     Running   0          3m33s

# Get container logs
kubectl logs sidecar-demo -c logging-agent

# Sample Output
Wed May 17 19:03:41 UTC 2023
Wed May 17 19:03:46 UTC 2023
Wed May 17 19:03:51 UTC 2023

# Run a command in a container
kubectl exec sidecar-demo -c application-server -- cat /tmp/log.txt

# Output
Wed May 17 19:03:41 UTC 2023
Wed May 17 19:03:46 UTC 2023
Wed May 17 19:03:51 UTC 2023

# Jump into a container to run commands
kubectl exec -it sidecar-demo -c application-server -- bash

# Now you're in the container's shell
root@sidecar-demo:/# 
root@sidecar-demo:/# ls /tmp
log.txt
```

Clean up.

```bash
kubectl delete -f sidecar-demo.yaml
```

## Conclusion

You should now have a basic undersatnding of the use of pods. You can see more details at the following articles:

* [Pod Lifecycle](https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/)
* [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/)

## Next Lab:

[Kubernetes Deployments](./deployments.md)