# Autoscaling Setup

One of the critical capabilities of any container orchestrator is the ability to automatically scale both your application and the hosting enviornment itself. AKS handles this through the combination of the Kubernetes [Horizontal Pod Autoscaler(HPA)](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/) and the AKS [Cluster Autoscaler](https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler). 

To emulate user load, this workshop recommends the use of [Azure Load Testing](https://docs.microsoft.com/en-us/azure/load-testing/overview-what-is-azure-load-testing).

Familiarize yourself with the HPA, Cluster Autoscaler and Azure Load Testing, review the requirements and complete the tasks.

## Autoscaling Requirements

* Cluster autoscaler should be enabled on both the System and User mode nodepools
  * System pool should have a min count of 1 and max count of 3
  * User pool should have a min count of 0 and a max count of 3
* Since were rapid testing we want the cluster autoscaler to:
  *  Scan every 5 seconds for scale up
  *  Scale down when a node isn't needed for 1 minute
  *  Allow scale down 1m after scale up

## Tasks:

1. Setup an Azure Load Testing instance to test the performance of the application: [Auto-Scaling with Horizontal Pod Autoscaler and Cluster Autoscaler](https://github.com/Azure/AKS-Landing-Zone-Accelerator/tree/main/Scenarios/Testing-Scalability)
1. Configure autoscaling for all nodepools based on the requirements above
1. Validate pod autoscaling is working
1. Validate cluster autoscaling is working

**Useful links:**

* [AKS Cluster Autoscaler](https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler)
* [Automatically scale a cluster to meet application demands on Azure Kubernetes Service (AKS)](https://docs.microsoft.com/en-us/azure/aks/cluster-autoscaler)
* [Examine the node and pod health](https://docs.microsoft.com/en-us/azure/architecture/operator-guides/aks/aks-triage-node-health)
* [Horizontal Pod Autoscaling](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)
* [Horizontal Pod Autoscaler Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
* [How to query logs from Container insights](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-log-query#resource-logs)
* [Reserve Compute Resources for System Daemons](https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/)
* [Safely Drain a Node](https://kubernetes.io/docs/tasks/administer-cluster/safely-drain-node/)
* [Quickstart: Create and run a load test with Azure Load Testing Preview](https://docs.microsoft.com/en-us/azure/load-testing/quickstart-create-and-run-load-test)
