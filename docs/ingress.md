# Setting up Ingress Control

Managing the flow of traffic into your application can be handled via direct access to the application's [Kubernetes Service](https://kubernetes.io/docs/concepts/services-networking/service/), however more Layer 7 (i.e. HTTP/HTTPS) control can be added by incorporating an ingress controller. At a minimum, ingress controllers will allow you to managed routes to different applications, components or version. However, ingress controllers can bring a lot of other features, including TLS offload.

## Pre-requisites

Make sure the following are complete before setting up ingress.

* Cluster is provisioned and accessible via 'kubectl'
* (Optional) App Deployment is complete
    * Alternatively you could deploy your own test application to try out ingress

## Ingress Control Requirements

* All ingress for the application must come through one public IP
* If the cluster is set up with egress lockdown, ingress must also flow through the firewall
* An analysis of ingress controller options has led you to use [Ingress-Nginx](https://github.com/kubernetes/ingress-nginx#readme)
* The ingress controller must live in it's own Kubernetes namespace
* TLS is **NOT** required for this initial test, but may be added if time permits
* The application should be accessible at http://<ingress-public-ip>/reddog

## Tasks:

1. Deploy the ingress controller
2. Create and test the ingress route
3. (Optional) Enable TLS on the ingress

**Useful links:**

* [Create an ingress controller in AKS](https://docs.microsoft.com/en-us/azure/aks/ingress-basic?tabs=azure-cli)
* [Use TLS with an ingress controller on AKS](https://docs.microsoft.com/en-us/azure/aks/ingress-tls?tabs=azure-cli)
* [Ingress Nginx](https://github.com/kubernetes/ingress-nginx#readme)
* [Kubernetes Ingress](https://kubernetes.io/docs/concepts/services-networking/ingress/)