## Monitoring Cheatsheet

#### _Azure Monitor_

*Create a Log Analytics Workspace*
```bash
WORKSPACEID=$(az monitor \
log-analytics workspace create \
-g CLUSTER-RG \
-n WORKSPACE-NAME \
| jq '.id')
```

*Enable Azure Container Insights on your cluster*
```bash
az aks enable-addons -a monitoring \
-n CLUSTERNAME \
-g CLUSTER-RG \ 
--workspace-resource-id $WORKSPACEID
```