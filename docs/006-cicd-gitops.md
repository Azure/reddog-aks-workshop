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
    * You will need to copy manifest file(s) from this repo into the forked repo from above
* Configure AKS GitOps to deploy applications using the above manifests/repo. https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2#for-azure-kubernetes-service-clusters


## Tasks:

1. Fork the source code [GitHub repo](https://github.com/CloudNativeGBB/reddog-code) into your own account
2. Create a manifests folder in your repo and configure the Kustomize files needed for Flux. Copy over the necessary manifests from this repo
3. Create a [GitHub Action](https://docs.github.com/en/actions) that will create a container image for all services
    > Note: For simplicity in the workshop, you can just set this up for 1 of the services (eg - accounting-service)
4. Add the following steps to your workflow: 
    * Setup environment and metadata for image (tags, repo, etc.)
    * Build Docker image
    * Push to Azure Container Registry
    * Update the manifest file with the new tag
5. Set the GH Action to trigger when updates are pushed to the `main` branch
6. Deploy the `k8s-configuration` extension into your AKS cluster
7. Setup a Flux configutation for the above service to ensure any updates are pulled into the cluster 
    > Note: The manifest files in the workshop use the `latest` tag. For this to work, these tags would need to be changed to a specific tag and updated in the CI/CD pipeline
    > Note: If you're using Egress Lockdown, you will need to ensure the Flux agents can access the source repo. https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2#network-requirements
8. Test everything end to end. You can update a random line of code and push to your fork to trigger the workflow. If you're successful, you will see a new pod deployment with your updated image.
9. (OPTIONAL) Add automated image scanning to CI/CD process. https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-cicd
 
**Useful links:**

* [GitHub Actions Docs](https://docs.github.com/en/actions)
* [GitOps with Flux on AKS](https://docs.microsoft.com/en-us/azure/azure-arc/kubernetes/tutorial-use-gitops-flux2#for-azure-kubernetes-service-clusters)
* [Flux with Kustomize](https://fluxcd.io/docs/components/kustomize/kustomization)