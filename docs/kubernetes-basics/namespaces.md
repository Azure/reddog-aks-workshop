# Kubernetes Namespaces

## Overview

In Kubernetes, namespaces provide a way to group resources together and apply certain levels of control, like role based access control and even some default resource limits. You can read all about namespaces in the upstream Kubernetes document listed below. We'll focus on a few of the basic commands for creation and management of namespaces in this lab.

[Kubernetes Namespaces](https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/)

### Namespace Creation and Deletion

<u>**Imperitive Approach**</u>

```bash
# List Namespaces
kubectl get ns

# Sample Output
NAME              STATUS   AGE
default           Active   11m
kube-node-lease   Active   11m
kube-public       Active   11m
kube-system       Active   11m
```

```bash
# Create Namesapce - Imperitive Method
kubectl create ns lab
```

```bash
# Describe Namesapce
kubectl describe ns lab

# Sample Output
Name:         lab
Labels:       kubernetes.io/metadata.name=lab
Annotations:  <none>
Status:       Active

No resource quota.

No LimitRange resource.
```

```bash
# Delete Namespace - Imperitive Method
kubectl delete ns lab
```

<u>**Declarative Approach**</u>

Create a new file called lab-namespace.yaml with the following contents:

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: lab
```

```bash
# Apply the manifest file
kubectl apply -f lab-namespace.yaml
```

```bash
# Check the namespaces was created
kubectl get ns

# Sample Output
NAME              STATUS   AGE
default           Active   25m
kube-node-lease   Active   25m
kube-public       Active   25m
kube-system       Active   25m
lab               Active   4s
```

### Run a pod in a namespace

```bash
# Start a pod in the lab namespace
kubectl run nginx --image=nginx --namespace lab
```

```bash 
# Get pods
kubectl get pods

# Sample Output
No resources found in default namespace.
```

To view resource deployed into a namespace you need to provide the namespace or update your config context to target your preferred namespace. When no namespace is provided, or set in context the 'default' namespace will be assumed.

```bash
# Check the namespace in your current context
kubectl config get-contexts

# Sample Output
CURRENT   NAME           CLUSTER   AUTHINFO                         NAMESPACE
*         reddog-admin   reddog    clusterAdmin_EphLabPrep_reddog   
```

Let's re-run the commands both by passing in a namespace and by setting it in context.

```bash
# Get pods passing in namesapce
kubectl get pods -n lab

# Sample Output
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          8s
```

```bash
# Update the namespace in context
kubectl config set-context --current --namespace lab

# Check the context namespace is set
kubectl config get-contexts

# Sample Output
CURRENT   NAME           CLUSTER   AUTHINFO                         NAMESPACE
*         reddog-admin   reddog    clusterAdmin_EphLabPrep_reddog   lab

# Now get pods without passing the namesapce parameter
kubectl get pods

# Sample Output
NAME    READY   STATUS    RESTARTS   AGE
nginx   1/1     Running   0          2m2s
```

## Conclusion

You should now have a basic undersatnding of the use of namespaces. You can see more details at the following articles:

* [Configure Memory and CPU Quotas for a Namespace](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/quota-memory-cpu-namespace/)
* [Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

## Next Lab:

[Kubernetes Pods](./pods.md)