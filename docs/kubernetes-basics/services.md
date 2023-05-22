# Kubernetes Services

## Overview

In Kubernetes, services provide a mechanism to expose your application pods through a single address, similar to a load balancer. A service works by using a label selector to find the pods that match the label, and then creating the necessary network connections within the cluster such that those pods are all exposed via a single ip address and fully qualified domain name. 

The services 'Type' attribute determines how that service is made accessible (ex. is the service accessible only internal to the cluster or external). You'll most often use ClusterIP and LoadBalancer as your service type. You should take a minute to read about Service Types at the link below before moving on:

* [Service Type](https://kubernetes.io/docs/concepts/services-networking/service/#publishing-services-service-types)

>**Note:** Services operate at layer 4, so they do not provide any layer 7 features, like HTTP path or header based routing or TLS. For that you should explore the [Ingress](../cheatsheets/ingress-cheatsheet.md) lab.

For more inforation on Services, check out the Kubernetes document below:

[Kubernetes Services](https://kubernetes.io/docs/concepts/services-networking/service/)

### Service Creation and Deletion

Services generally operate over a Kubernetes deployment, so we'll need to start with that. If you still have your nginx-deployment.yaml from before, you can reuse that, or you can create a new nginx-deployment.yaml file with the following contents.

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

Apply the deployment.

```bash
kubectl apply -f nginx-deployment.yaml
```

<u>**Imperitive Approach**</u>

When working from the command line, you can just run the 'expose' command to create a service.

```bash
# Expose the deployment on port 80
kubectl expose deployment nginx --port=80

# Check out the service
kubectl get svc -o wide

# Sample Output
# Notice the 'SELECTOR' matches the pod label from the deployment
NAME    TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)   AGE    SELECTOR
nginx   ClusterIP   10.0.218.82   <none>        80/TCP    5m2s   app=nginx
```

As you can see, the 'Type' is 'ClusterIP', which if you read the article listed above...you should know that this service is only accessible within the cluster. Let's test it. We'll first need to start a pod on the cluster we can use for the test. We'll use 'busybox', which is a common image for basic testing operations in your cluster.

```bash
# Start a busy box pod
# -it below ask for an interactive termintal
# --rm below tells kubernetes to delete this pod when we exit
kubectl run busybox --image=busybox -it --rm -- sh

# From within the running pod, call the service by the ip above
wget -qO - 10.0.218.82

# Now try with the service name
wget -qO - nginx

# Sample output
# In both cases you should have gotten the following back
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

Why did both the service name and the IP work properly? It's because Kubernetes has it's own DNS Server running. In AKS it's [CoreDNS](https://coredns.io/). We can take a quick look at CoreDNS by running an 'nslookup'.

```bash
# Back in the busybox pod, run an nslookup
nslookup nginx

# Sample Ouput
Server:         10.0.0.10
Address:        10.0.0.10:53

Name:   nginx.lab.svc.cluster.local
Address: 10.0.218.82
```

As you can see from the above, when we created the service, Kubernetes automatically registered it with CoreDNS. The fully qualified domain name of the service is nginx.lab.svc.cluster.local, but Kubernetes will also allow you to access that service at: nginx.lab, nginx.lab.svc, etc.

Now let's delete the service and try again via the declarative approach.

```bash
# If you havent already, exit the busy box pod by typing 'exit'
# Delete the service
kubectl delete svc nginx
```

<u>**Declarative Approach**</u>

Start by creating a new file called nginx-svc.yaml, and paste in the following:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

Apply the manifest file. Notice that we set the service 'type' to 'LoadBalancer'. This will tell Kubernetes to call out to Azure to provision a new public IP and create the load balancing rule on the AKS load balancer for the service. This may take a few seconds to complete.

```bash
# Check the service
kubectl get svc

# Sample Output
NAME        TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE
nginx-svc   LoadBalancer   10.0.173.36   20.253.52.110   80:30463/TCP   85s
```

Get the 'external-ip' value from above, open a browser and go to http://EXTERNAL-IP

You should be taken to the nginx main page.

### Endpoints

If you want to see a bit more about how Services work, run the following command to see the service, the pods used by the service, and the endpoints that connect the service to the backend pods.

```bash
# Get the svc, pods and endpoints in wide output format
kubectl get svc,pods,endpoints -o wide

# Sample Output
NAME                TYPE           CLUSTER-IP    EXTERNAL-IP     PORT(S)        AGE     SELECTOR
service/nginx-svc   LoadBalancer   10.0.173.36   20.253.52.110   80:30463/TCP   4m42s   app=nginx

NAME                         READY   STATUS    RESTARTS   AGE   IP            NODE                                NOMINATED NODE   READINESS GATES
pod/nginx-7467c7b65c-nl2gz   1/1     Running   0          80m   10.244.0.33   aks-nodepool1-40230841-vmss000001   <none>           <none>
pod/nginx-7467c7b65c-t829q   1/1     Running   0          80m   10.244.1.38   aks-nodepool1-40230841-vmss000000   <none>           <none>
pod/nginx-7467c7b65c-trm7j   1/1     Running   0          80m   10.244.2.51   aks-nodepool1-40230841-vmss000002   <none>           <none>

NAME                  ENDPOINTS                                      AGE
endpoints/nginx-svc   10.244.0.33:80,10.244.1.38:80,10.244.2.51:80   4m42s
```

Now you can delete the svc and deployment.

```bash
# Delete the service
kubectl delete -f nginx-svc.yaml

# Delete the deployment
kubectl delete -f nginx-deployment.yaml
```

## Conclusion

You should now have a basic undersatnding of the use of Kubernetes Services. You can see more details at the following articles:

* [Services](https://kubernetes.io/docs/concepts/services-networking/service/)
* [DNS for Services and Pods](https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/)
* [Use a public standard load balancer in Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/load-balancer-standard)
* [Use an internal load balancer with Azure Kubernetes Service](https://learn.microsoft.com/en-us/azure/aks/internal-lb)

## Next Lab:

[Kubernetes Jobs](./jobs.md)