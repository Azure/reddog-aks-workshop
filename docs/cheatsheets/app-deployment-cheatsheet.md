## App Deployment Cheatsheet

```bash
RG=RedDogAKSWorkshop
LOC=eastus
VNET_NAME=reddog-vnet
let "randomIdentifier=$RANDOM*$RANDOM"
SB_NAMESPACE="reddogsb$randomIdentifier"
SQLSERVER="$randomIdentifier-azuresql-server"
SQLDB="reddog"
SQLLOGIN='azureuser'
SQLPASSWORD='w@lkingth3d0g'
# Get your current IP
MYIP=$(curl icanhazip.com)
REDIS_PASSWD='w@lkingth3d0g'
REDIS_SERVER='redis-release-master.redis.svc.cluster.local:6379'

# Deploy Azure Service Bus
az servicebus namespace create --resource-group $RG --name $SB_NAMESPACE --location $LOC

# https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-cli

# Deploy Azure SQL, Database, and Firewall rule
az sql server create --name $SQLSERVER --resource-group $RG --location $LOC --admin-user $SQLLOGIN --admin-password $SQLPASSWORD

az sql server firewall-rule create --resource-group $RG --server $SQLSERVER -n AllowYourIp --start-ip-address $MYIP --end-ip-address $MYIP # for your machine if needed
az sql server firewall-rule create --resource-group $RG --server $SQLSERVER -n AllowYourIp --start-ip-address '0.0.0.0' --end-ip-address '0.0.0.0' # for all Azure services

#####################################################
# ONLY IF YOU FOLLOWED THE EGRESS LOCKDOWN SETUP
FIREWALL_IP=$(az network public-ip show -g $RG -n azfirewall-ip -o tsv --query ipAddress)
az sql server firewall-rule create --resource-group $RG --server $SQLSERVER -n AllowYourIp --start-ip-address $FIREWALL_IP --end-ip-address $FIREWALL_IP
#####################################################

az sql db create --resource-group $RG --server $SQLSERVER --name $SQLDB --edition GeneralPurpose --family Gen5 --capacity 2 --zone-redundant false

# https://docs.microsoft.com/en-us/azure/azure-sql/database/scripts/create-and-configure-database-cli?view=azuresql

# Deploy Redis (Helm)
helm repo add dapr https://dapr.github.io/helm-charts
helm repo add azure-marketplace https://marketplace.azurecr.io/helm/v1/repo
helm repo update

kubectl create ns redis

helm install redis-release azure-marketplace/redis --namespace redis --set auth.password=$REDIS_PASSWD --set replica.replicaCount=2

# Deploy Dapr (Helm)
kubectl create ns dapr-system

helm install dapr dapr/dapr --namespace dapr-system

# Create AKS Secrets - first get values for creds

# Get Service Bus Connection String
SB_CONNECT_STRING=$(az servicebus namespace authorization-rule keys list --resource-group $RG --namespace-name $SB_NAMESPACE --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)
echo $SB_CONNECT_STRING

# Fix password if needed
az sql server update --name $SQLSERVER --resource-group $RG --admin-password $SQLPASSWORD

# Get SQL Connection String
SQL_CONNECTION_STRING="Server=tcp:${SQLSERVER}.database.windows.net,1433;Database=reddog;User ID=${SQLLOGIN};Password=${SQLPASSWORD};Encrypt=true;Connection Timeout=30;"
echo $SQL_CONNECTION_STRING

# Create secrets
kubectl create ns reddog
kubectl create secret generic reddog.secrets \
    --namespace reddog \
    --from-literal=sb-connect-string=$SB_CONNECT_STRING \
    --from-literal=redis-password=$REDIS_PASSWD \
    --from-literal=redis-server=$REDIS_SERVER 

kubectl create secret generic reddog-sql \
    --namespace reddog \
    --from-literal=reddog-sql="$SQL_CONNECTION_STRING"

# Deploy Red Dog Dapr configs
kubectl apply -f ./manifests/workshop/dapr-components
kubectl apply -f ./manifests/workshop/reddog-services/rbac.yaml

# Deploy Red Dog services
kubectl apply -f ./manifests/workshop/reddog-services/bootstrapper.yaml
kubectl apply -f ./manifests/workshop/reddog-services/accounting-service.yaml
kubectl apply -f ./manifests/workshop/reddog-services/loyalty-service.yaml
kubectl apply -f ./manifests/workshop/reddog-services/order-service.yaml
kubectl apply -f ./manifests/workshop/reddog-services/make-line-service.yaml
kubectl apply -f ./manifests/workshop/reddog-services/virtual-worker.yaml
kubectl apply -f ./manifests/workshop/reddog-services/virtual-customers.yaml
kubectl apply -f ./manifests/workshop/reddog-services/services-for-ui.yaml
kubectl apply -f ./manifests/workshop/reddog-services/ui.yaml

# Test deployment with resource requests/limits
kubectl apply -f ./manifests/workshop-cheatsheet/reddog-services/order-service.yaml

# NSG's - Note that Microsoft Corp Security blocks all in/out traffic with an NSG (need to add rules)

```

### Accessing the App

If you didn't follow the egress lockdown path, you should be able to simply run the following to get the public IP of the UI and browse to it.

```bash
# Get the UI Service Public IP
kubectl get svc -n reddog
NAME                      TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)                               AGE
accounting-service        ClusterIP      10.245.0.51    <none>           8083/TCP                              18m
accounting-service-dapr   ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   19h
loyalty-service-dapr      ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   19h
make-line-service         ClusterIP      10.245.0.126   <none>           8082/TCP                              18m
make-line-service-dapr    ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   19h
order-service             ClusterIP      10.245.0.166   <none>           8081/TCP                              18m
order-service-dapr        ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   19h
ui                        LoadBalancer   10.245.0.201   20.237.123.135   80:31828/TCP                          18m
ui-dapr                   ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   19h
virtual-customers-dapr    ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   19h
virtual-worker-dapr       ClusterIP      None           <none>           80/TCP,50001/TCP,50002/TCP,9090/TCP   19h

# In your browser, given the above, you'd navigate to http://20.237.123.135/
```

If you **DID** follow the egress lockdown path, things are a bit more complicated. The easy way to connect to the UI is with a kubectl port-forward, to map a port on your local machine to the service.

> **NOTE:**
> Port forwards will not work in cloud shell. You need to do them from your local machine.

```bash
# Forward local port 8080 to the service port 80
kubectl port-forward svc/ui 8080:80 -n reddog
Forwarding from 127.0.0.1:8080 -> 8080
Forwarding from [::1]:8080 -> 8080

# In your browser you'd navigate to http://localhost:8080/
```

At this point you should see the page load. If the tables and charts arent loading, consider checking your firewall rules to make sure Azure Service Bus and Azure SQL are permitted to egress on their respective ports.