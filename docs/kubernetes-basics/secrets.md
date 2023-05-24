# Kubernetes Secrets

## Overview

In Kubenernetes, you may need to store sensitive data (ex. Connection Strings, Passwords, etc). Kubernetes provides the secret object for this purpose. It's important to note that secret data is base64 encoded, not encrypted. FOr a more secure secret store, look at the Azure Key Vault CSI driver or other solution (ex. Hashi Vault). For more info you can check the article below:

[Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)

### Secret Creation and Deletion

<u>**Imperitive Approach**</u>

```bash
# Create a secret
kubectl create secret generic prod-db-secret --from-literal=username=produser --from-literal=password=Y4nys7f11

# Show the secret
kubectl get secrets

# Sample Output
NAME                                 TYPE                 DATA   AGE
prod-db-secret                       Opaque               2      13s

# Show the secret data and base64 decode
kubectl get secret prod-db-secret -o jsonpath='{.data.username}'|base64 --decode

# Delete the secret
kubectl delete secret prod-db-secret
```

<u>**Declarative Approach**</u>

```bash
# Generate a secret manifest
kubectl create secret generic prod-db-secret --from-literal=username=produser --from-literal=password=Y4nys7f11 --dry-run=client -o yaml>secret.yaml
```

Your secret.yaml should look like the following:

```yaml
apiVersion: v1
data:
  password: WTRueXM3ZjEx
  username: cHJvZHVzZXI=
kind: Secret
metadata:
  creationTimestamp: null
  name: prod-db-secret
```

```bash
# Apply the manifest
kubectl apply -f secret.yaml
```

Now that we have a secret, lets us it in a pod. Create a file called secret-pod.yaml with the following contents:

```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginx
  name: nginx
spec:
  containers:
  - image: nginx
    name: nginx
    volumeMounts:
    - name: secret-volume
      readOnly: true
      mountPath: "/etc/secret-volume"
  volumes:
  - name: secret-volume
    secret:
      secretName: prod-db-secret
```

Now deploy the pod.

```bash
# Deploy the pod
kubectl apply -f secret-pod.yaml

# Check that the pod started
kubectl get pods

# Check that the secret was mounted
kubectl exec -it nginx -- ls /etc/secret-volume

# Check the secret values
kubectl exec -it nginx -- cat /etc/secret-volume/username

# Describe the pod, to see the secret mount
kubectl describe pod nginx

# Sample Output - Notice the volume mounts
Name:             nginx
Namespace:        lab
Priority:         0
Service Account:  default
Node:             aks-nodepool1-40230841-vmss000001/10.224.0.4
Start Time:       Wed, 24 May 2023 09:40:36 -0400
Labels:           run=nginx
Annotations:      <none>
Status:           Running
IP:               10.244.0.69
IPs:
  IP:  10.244.0.69
Containers:
  nginx:
    Container ID:   containerd://82d7ecca626d49063c76182191fbe81c597403c0dd0225133cf7a22aabb736f5
    Image:          nginx
    Image ID:       docker.io/library/nginx@sha256:f5747a42e3adcb3168049d63278d7251d91185bb5111d2563d58729a5c9179b0
    Port:           <none>
    Host Port:      <none>
    State:          Running
      Started:      Wed, 24 May 2023 09:40:41 -0400
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /etc/secret-volume from secret-volume (ro)
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-zwx4t (ro)
Conditions:
  Type              Status
  Initialized       True 
  Ready             True 
  ContainersReady   True 
  PodScheduled      True 
Volumes:
  secret-volume:
    Type:        Secret (a volume populated by a Secret)
    SecretName:  prod-db-secret
    Optional:    false
  kube-api-access-zwx4t:
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
  Normal  Scheduled  32s   default-scheduler  Successfully assigned lab/nginx to aks-nodepool1-40230841-vmss000001
  Normal  Pulling    33s   kubelet            Pulling image "nginx"
  Normal  Pulled     29s   kubelet            Successfully pulled image "nginx" in 4.048382585s (4.048387495s including waiting)
  Normal  Created    28s   kubelet            Created container nginx
  Normal  Started    28s   kubelet            Started container nginx

```


## Conclusion

You should now have a basic undersatnding of the use of secrets. You can see more details at the following articles:

* [Kubernetes Secrets](https://kubernetes.io/docs/concepts/configuration/secret/)
