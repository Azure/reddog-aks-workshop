# Cluster Upgrades

Kubernetes frequently gets patches and upgrades, addressing security vulnerabilities and adding new functionality. Additionally, AKS releases patches for the underlying node operating system on a regular basis (aka Node Image Updates). You need to implement a process to upgrade the cluster.

## Pre-requisites

Make sure the following are complete before setting up ingress.

* Cluster is provisioned and accessible via 'kubectl'
* App Deployment is complete

## Upgrade Requirements

* Initial testing should use a manual upgrade process
* The UI running pod count should be increased to 2
* The UI pod count should never go below 1 during an upgrade
* Day 1 (simulated): Due to a critical OS level CVE you've been asked to upgrade the system pool **NODE IMAGE ONLY**
* Day 2 (simulated): Due to a critical Kubernetes level CVI you've been asked to upgrade the control plane and the system pool Kubernetes version to the next incremental version (major or minor)
* Day 3 (simulated): To take advantage of some new Kubernetes features you've been asked to upgrade the user pool Kubernetes version to the next incremental version (major or minor)

## Tasks:

1. Increase the Red Dog UI deployment replica count to 2
2. Deploy the necessary config to ensure the UI pod count never dips below 1 pod
3. Check the available upgrade versions for Kubernetes and Node Image
4. Upgrade the system pool node image
5. Upgrade the AKS control plane and system pool Kubernetes version
6. Upgrade the user pool Kubernetes version

    **Bonus Tasks:**
7. Enable Automatic Upgrades to the 'patch' channel and set a Planned Maintenance Window (preview) for Saturdays at 1am


**Useful links:**

* [Best practices for cluster security and upgrades in Azure Kubernetes Service](https://docs.microsoft.com/en-us/azure/aks/operator-best-practices-cluster-security?tabs=azure-cli)
* [AKS Upgrades](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster?tabs=azure-cli)
* [Deployment Scaling](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#scaling-a-deployment)
* [Voluntary and Involuntary Disruptions](https://kubernetes.io/docs/concepts/workloads/pods/disruptions/)
* [Kubernetes Pod Disruption Budgets](https://kubernetes.io/docs/tasks/run-application/configure-pdb/)
* [Node Surge](https://docs.microsoft.com/en-us/azure/aks/upgrade-cluster?tabs=azure-cli#customize-node-surge-upgrade)
* [AKS Auto Upgrade](https://docs.microsoft.com/en-us/azure/aks/auto-upgrade-cluster)
  