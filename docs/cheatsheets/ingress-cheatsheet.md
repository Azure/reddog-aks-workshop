## Autoscaling Setup Cheatsheet

In autoscaling setup, you were given the following requirements:

* All ingress for the application must come through one public IP
* If the cluster is set up with egress lockdown, ingress must also flow through the firewall
* An analysis of ingress controller options has led you to use [Ingress-Nginx](https://github.com/kubernetes/ingress-nginx#readme)
* The ingress controller must live in it's own Kubernetes namespace
* TLS is **NOT** required for this initial test, but may be added if time permits
* The application should be accessible at http://\<ingress-public-ip\>/reddog

You were asked to complete the following tasks:

1. Deploy the ingress controller
2. Create and test the ingress route
3. (Optional) Enable TLS on the ingress


### Deploy the Ingress Controller

You were given the requirement to use ingress-nginx, which fortunately is the same ingress controller used in the AKS documentation for ingress setup, so we can just follow that. 

> **NOTE**
> If you followed the egress lockdown approach you'll need to follow the steps for setting up the ingress controller with a private IP and will then need to set up a public IP on the firewall for the ingress traffic. This is a standard networking requirement for forced traffic flows. There are various alternative solutions, but ultimately the path traffic takes into the cluster needs to be the path that traffic flows out of the cluster, and our forced egress route (0.0.0.0/0 next hop to the firewall) leads us to need to be more careful with the ingress path as well.

<br/>

<u>**WITHOUT Egress Lockdown**</u>


> **NOTE**
> Don't forget that any new images registries you pull from need to be allowed through the firewall. 
> The repository holding the ingress-nginx images is listed in the egress lockdown cheatsheet.

```bash
NAMESPACE=ingress

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace \
--namespace $NAMESPACE \
--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz 

# After completing run the following to check the install status
kubectl get svc,pods -n ingress
NAME                                         TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)                      AGE
service/ingress-nginx-controller             LoadBalancer   10.245.0.102   20.237.123.135 80:32713/TCP,443:31754/TCP   87s
service/ingress-nginx-controller-admission   ClusterIP      10.245.0.180   <none>         443/TCP                      87s

NAME                                            READY   STATUS    RESTARTS   AGE
pod/ingress-nginx-controller-55dcf56b68-m4hdb   1/1     Running   0          87s
```

Deploy the Ingress configuration.

```bash
# Apply the ingress manifest
kubectl apply -f ../../manifests/workshop-cheatsheet/ingress/ingress.yaml -n reddog

# Check ingress status
kubectl get ingress -n reddog
NAME               CLASS   HOSTS   ADDRESS      PORTS   AGE
reddog-ui          nginx   *       10.140.0.6   80      66m
reddog-ui-static   nginx   *       10.140.0.6   80      56m
```

Now that your ingress is running you can access the site at http://\<svc external ip\>/reddog

<br/>

<u>**Egress Lockdown Approach**</u>

> **NOTE**
> Don't forget that any new images registries you pull from need to be allowed through the firewall. 
> The repository holding the ingress-nginx images is listed in the egress lockdown cheatsheet.

Create a new file called internal-ingress.yaml and paste the following:

```yaml
controller:
  service:
    annotations:
      service.beta.kubernetes.io/azure-load-balancer-internal: "true"
```

```bash
NAMESPACE=ingress

helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
--create-namespace \
--namespace $NAMESPACE \
--set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
-f internal-ingress.yaml

# After completing run the following to check the install status
kubectl get svc,pods -n ingress
NAME                                         TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
service/ingress-nginx-controller             LoadBalancer   10.245.0.102   10.140.0.6    80:32713/TCP,443:31754/TCP   87s
service/ingress-nginx-controller-admission   ClusterIP      10.245.0.180   <none>        443/TCP                      87s

NAME                                            READY   STATUS    RESTARTS   AGE
pod/ingress-nginx-controller-55dcf56b68-m4hdb   1/1     Running   0          87s
```

Now that your ingress is running you can port-forward to access the site, until you open up a public IP for your ingress controller.

```bash
# Port forward to the ingress controller
kubectl port-forward svc/ingress-nginx-controller -n ingress 8080:80
Forwarding from 127.0.0.1:8080 -> 80
Forwarding from [::1]:8080 -> 80
Handling connection for 8080
Handling connection for 8080
Handling connection for 8080
...

# In your browser navigate to http://localhost:8080/reddog
```

Now, to access from the public Internet, we can add a new IP and NAT rule to the firewall.

```bash
# Create a public IP for the ingress controller
az network public-ip create -g $RG -n ingress-ip --sku "Standard"

# Add the public IP to the firewall
az network firewall ip-config create -g $RG -f $FIREWALLNAME -n aks-ingress --public-ip-address ingress-ip

# Get the public IP
INGRESS_EXTERNAL_IP=$(az network public-ip show -g $RG -n ingress-ip -o tsv --query ipAddress)

# Get the private IP of the ingress service
INGRESS_INTERNAL_IP=$(kubectl get svc ingress-nginx-controller -n ingress -o yaml -o=jsonpath='{.status.loadBalancer.ingress[0].ip}')

# Create the HTTP NAT rule
az network firewall nat-rule create  \
--resource-group $RG \
--firewall-name $FIREWALLNAME \
--name ingress-nat \
--collection-name ingress-nat-http \
--source-addresses '*' \
--dest-addr $INGRESS_EXTERNAL_IP \
--translated-address $INGRESS_INTERNAL_IP \
--protocols TCP \
--destination-ports 80 \
--translated-port 80 \
--priority 100 \
--action Dnat

# Create the HTTPS NAT rule
# Note: Setting up 443 isn't needed unless you also set up TLS on the ingress
az network firewall nat-rule create  \
--resource-group $RG \
--firewall-name $FIREWALLNAME \
--name ingress-nat \
--collection-name ingress-nat-https \
--source-addresses '*' \
--dest-addr $INGRESS_EXTERNAL_IP \
--translated-address $INGRESS_INTERNAL_IP \
--protocols TCP \
--destination-ports 443 \
--translated-port 443 \
--priority 101 \
--action Dnat
```

Now you should be able to navigate to http://\<INGRESS_EXTERNAL_IP\>/reddog and test the UI is working as expected.


## Bonus

If you want to try with TLS, you can follow the setup guide from AKS documentation below and merge with the steps above. 

[https://docs.microsoft.com/en-us/azure/aks/ingress-tls?tabs=azure-cli](https://docs.microsoft.com/en-us/azure/aks/ingress-tls?tabs=azure-cli)

You'll need to:

1. Install ingress-nginx (look above for egress lockdown vs non-lockdown changes to the install)
2. Get a public IP with an FQDN or set the FQDN on the IP created for you when you set up the ingress
3. Install cert-manager (may require additional egress firewall rules)
4. Create the cert issuer
5. Create the Ingress config
6. Test



