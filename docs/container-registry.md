# Image Management / Container Registry

## Notes

At this point, you should have an AKS cluster fully deployed and the Red Dog application up and running in your subscription. 


## Azure Container Registry Requirements

* The Azure Container Registry (ACR) resource should reside in your resource group and in the same Azure region
* If geo-replication is required, use the Premium SKU
* The managed identity for the AKS Kubelet should have pull access at a minimum to your ACR instance


## Image Security Requirements

* Automate image scanning to ensure any images created for the app are properly scanned for vulnerabilities
    * Multiple options for this scenario:
        * Microsoft Defender for Containers. https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-enable
        * Qualys. https://www.qualys.com 
        * Aqua Security. https://www.aquasec.com 
        * Twistlock (Prisma)
        * Anchore. https://anchore.com
            * Grype (OSS). https://github.com/anchore/grype
        * Falco. https://falco.org
* Read details on Private Endpoints with ACR. For this workshop, we will be setting up GitHub Actions and this step should be skipped (for simplicity)


## Tasks:

1. Create an ACR resource
2. Ensure that the managed identity for the AKS Kubelet (created earlier in the workshop) has access to pull images from the ACR https://docs.microsoft.com/en-us/azure/container-registry/container-registry-authentication-managed-identity?tabs=azure-cli 
3. Manually push copies of the Red Dog services to your ACR (automation will be handled in a later module)
4. Setup automated image scanning for Red Dog container images using one of the following:
    * Microsoft Defender for Cloud. https://docs.microsoft.com/en-us/azure/container-registry/scan-images-defender
    * GitHub Action Scanning. https://docs.microsoft.com/en-us/azure/container-registry/github-action-scan 
    * Use a custom tool such as: 
        * [Qualys](https://qualysguard.qg2.apps.qualys.com/cs/help/vuln_scans/docker_images.htm) 
        * [Anchore](https://anchore.com/opensource)
        * For production, we recommend using a Enterprise grade tool such as [Aqua Security](https://www.aquasec.com) or [Prisma/Twistlock](https://www.paloaltonetworks.com/prisma/cloud/cloud-workload-protection-platform/container-security)


**Useful links:**

* [Azure Container Registry documentation](https://docs.microsoft.com/en-us/azure/container-registry)
