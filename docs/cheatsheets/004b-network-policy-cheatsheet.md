## Network Policy Cheatsheet

In network policy, you were given the following requirements:

* The reddog namespace should deny all ingress traffic by default
* The reddog namespace should allow ingress traffic only from the ingress controller namespace and itself

You were asked to complete the following tasks:

1. Verify that calico is installed
2. Create the ingress network policy


### Verify that calico is installed

There are a few ways you can check for calico installation below.

```bash
# Via Azure CLI
RG=RedDogAKSWorkshop
CLUSTER_NAME=reddog-griffith

az aks show -g $RG -n $CLUSTER_NAME -o tsv --query networkProfile.networkPolicy

# output
calico

# Check for Calico CRDs in the cluster
kubectl get crd|grep projectcalico

# Output
bgpconfigurations.crd.projectcalico.org                            2022-08-08T20:16:45Z
bgppeers.crd.projectcalico.org                                     2022-08-08T20:16:45Z
blockaffinities.crd.projectcalico.org                              2022-08-08T20:16:45Z
caliconodestatuses.crd.projectcalico.org                           2022-08-08T20:16:45Z
clusterinformations.crd.projectcalico.org                          2022-08-08T20:16:45Z
felixconfigurations.crd.projectcalico.org                          2022-08-08T20:16:45Z
globalnetworkpolicies.crd.projectcalico.org                        2022-08-08T20:16:45Z
globalnetworksets.crd.projectcalico.org                            2022-08-08T20:16:45Z
hostendpoints.crd.projectcalico.org                                2022-08-08T20:16:45Z
ipamblocks.crd.projectcalico.org                                   2022-08-08T20:16:45Z
ipamconfigs.crd.projectcalico.org                                  2022-08-08T20:16:45Z
ipamhandles.crd.projectcalico.org                                  2022-08-08T20:16:45Z
ippools.crd.projectcalico.org                                      2022-08-08T20:16:45Z
ipreservations.crd.projectcalico.org                               2022-08-08T20:16:45Z
kubecontrollersconfigurations.crd.projectcalico.org                2022-08-08T20:16:45Z
networkpolicies.crd.projectcalico.org                              2022-08-08T20:16:45Z
networksets.crd.projectcalico.org                                  2022-08-08T20:16:45Z
```

### Create the ingress network policy

The requirements say that we need to disable ingress to the reddog namespace by default. We can do this with a default ingress deny policy like the following:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: reddog
spec:
  podSelector: {}
  policyTypes:
  - Ingress
```

Next we can selectively allow ingress from the ingress controller namespace. We must also allow ingress from the reddog namespace itself.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress
  namespace: reddog
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  ingress:
    - from:
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: reddog
        - namespaceSelector:
            matchLabels:
              kubernetes.io/metadata.name: ingress
```

Create your own manifests using the above and apply to the reddog namespace, or apply as follows from the repo:

```bash
kubectl apply -f ./manifests/workshop-cheatsheet/network-policy/reddog-default-deny-ingress.yaml
kubectl apply -f ./manifests/workshop-cheatsheet/network-policy/reddog-ns-allow.yaml
```

### Test your changes

You can test access to the UI via either the ingress endpoint, if you completed the [ingress control](ingress-cheatsheet.md) setup. If you didn't complete the ingress setup, you can just use a port forward as shown below:

```bash
kubectl port-forward svc/ui 8080:80

Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080

# Browse to http://localhost:8080
```

You should also test the other ingress is blocked by default. To do this you can deploy a test pod to another namespace and try to run a curl.

```bash
# Create a temporary pod in the default namespace
# Note: the --rm will cause the pod to be removed when you exit. 
kubectl run -it --rm ubuntu --image=ubuntu -n default -- bash

# In the pod shell run the following to install curl
apt update;apt install -y curl

# In another terminal get the UI service IP
kubectl get svc -n reddog

# Output
NAME                      TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                               AGE
accounting-service        ClusterIP      10.245.0.51    <none>           8083/TCP                              25h
accounting-service-dapr   ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   44h
loyalty-service-dapr      ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   44h
make-line-service         ClusterIP      10.245.0.126   <none>           8082/TCP                              25h
make-line-service-dapr    ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   44h
order-service             ClusterIP      10.245.0.166   <none>           8081/TCP                              25h
order-service-dapr        ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   44h
ui                        LoadBalancer   10.245.0.201   20.237.123.135   80:31828/TCP                          25h
ui-dapr                   ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   44h
virtual-customers-dapr    ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   44h
virtual-worker-dapr       ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   44h

# Now back in the ubuntu pod, try to curl the 'Cluster-IP' of the ui service
curl 10.245.0.201

# Output
curl: (28) Failed to connect to 10.245.0.201 port 80 after 129813 ms: Connection timed out
```

You can re-run the steps above and target either the 'ingress' or 'reddog' namespaces for the ubuntu pod deployment, and you'll see that both namespaces are able to curl the UI.


## Bonus

If you want to explore network policy further, you should explore the labs provided in the Kubernetes Hackfest at the link below. You'll find labs for both the Open Source Calico project, as well as steps to try out Calico Cloud by Tigera, which gives you a managed cloud portal for managing and viewing network policy in your AKS cluster.

[Calico on AKS](https://github.com/Azure/kubernetes-hackfest/blob/master/labs/networking/calico-lab-exercise/README.md)



