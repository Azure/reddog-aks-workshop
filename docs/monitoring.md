# Monitoring 

## Notes

At this point, you should have an AKS cluster fully deployed and the Red Dog application up and running in your subscription. 


## Azure Monitor Requirements

> Azure Monitor / Log Analytics Workspaceresource should reside in your resource group and in the same Azure region.

## Tasks:

**Azure Monitor**
1. Create a log analytics workspace
2. Enable container insights on your cluster with aforementioned workspaceid

_OPTIONAL TASKS_

**Promethus & Grafana**
1. Install/Deploy Prometheus/Grafana 
2. Apply the privileged pod policy at the cluster level
3. Test the policy is operating as expected

**Useful links**

* [Enable monitoring for an existing AKS cluster](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-enable-existing-clusters?tabs=azure-cli)
* [kube-prometheus github](https://github.com/prometheus-operator/kube-prometheus)
* [kube-prometheus customizations](https://github.com/prometheus-operator/kube-prometheus/tree/main/docs/customizations)
* [Configure distributed tracing with App Insights](https://docs.dapr.io/operations/monitoring/tracing/open-telemetry-collector-appinsights/)