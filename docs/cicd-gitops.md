# CI/CD and GitOps

## Notes

At this point, you should have an AKS cluster fully deployed and the Red Dog application up and running in your subscription. 

The goal in this module is to create a pipeline that will auto create container images for the Red Dog services and GitOps will be used to deploy any updates to the cluster.


## CI/CD Requirements

* The source code Github repository should be forked into your own account
    * Source code is in a separate repo: https://github.com/CloudNativeGBB/reddog-code
* Create a CI/CD pipeline that will create images for Red Dog services
* The pipeline should be automatically triggered based on code updates


## GitOps Requirements

* Store manifest files (YAML) for the Red Dog services in the forked repo
    * You will need to copy files from this repo into the forked repo from above
* Configure AKS GitOps to deploy applications using the above manifests/repo. https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2#for-azure-kubernetes-service-clusters


## Tasks:

1. Fork the source code [GitHub repo](https://github.com/CloudNativeGBB/reddog-code) into your own account
2. Create a [GitHub Action](https://docs.github.com/en/actions) that will create a container image for all services
    > Note: For simplicity in the workshop, you can just set this up for 1 of the services (eg - order-service)
3. Set the GH Action to trigger when updates are pushed to the `main` branch
4. Deploy the `k8s-configuration` extension into your AKS cluster
5. Setup a Flux configutation for the above service to ensure any updates are pulled into the cluster 
    > Note: The manifest files in the workshop use the `latest` tag. For this to work, these tags would need to be changed to a specific tag and updated in the CI/CD pipeline

 
**Useful links:**

* [GitOps with Flux on AKS](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2#for-azure-kubernetes-service-clusters)
