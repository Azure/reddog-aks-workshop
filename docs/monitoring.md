# Monitoring 

## Notes

At this point, you should have an AKS cluster fully deployed and the Red Dog application up and running in your subscription. 


## Tasks:

-- Choose one --

** Azure Monitor **
1. Enable container insights on your cluster


** Promethus **
2. Apply the privileged pod policy at the cluster level
3. Test the policy is operating as expected

**Useful links**


* [Enable monitoring for an existing AKS cluster](https://docs.microsoft.com/en-us/azure/azure-monitor/containers/container-insights-enable-existing-clusters?tabs=azure-cli)

* [kube-prometheus github](https://github.com/prometheus-operator/kube-prometheus)
* [kube-prometheus customizations](https://github.com/prometheus-operator/kube-prometheus/tree/main/docs/customizations)

* [Configure distributed tracing with App Insights](https://docs.dapr.io/operations/monitoring/tracing/open-telemetry-collector-appinsights/)

## Pre-requisites