# Autoscaling Setup

One of the critical capabilities of any container orchestrator is the ability to automatically scale both your application and the hosting enviornment itself. AKS handles this through the combination of the Kubernetes [Horizontal Pod Autoscaler(HPA)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) and the AKS [Cluster Autoscaler](https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler). 

Familiarize yourself with the HPA and Cluster Autoscaler, review the requirements and complete the tasks.

## Autoscaling Requirements

* Cluster autoscaler should be enabled on both the System and User mode nodepools
  * System pool should have a min count of 1 and max count of 3
  * User pool should have a min count of 0 and a max count of 3
* Since were rapid testing we want the cluster autoscaler to:
  *  Scan every 5 seconds for scale up
  *  Scale down when a node isn't needed for 1 minute
  *  Allow scale down 1m after scale up

## Task:

1. Configure autoscaling for all nodepools based on the requirements above
2. Validate pod autoscaling is working
3. Validate cluster autoscaling is working

**Useful links:**

* [Kubernetes Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
* [AKS Cluster Autoscaler](https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler)

### Next:

**TBD**