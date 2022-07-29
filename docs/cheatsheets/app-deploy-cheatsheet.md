## App Deployment Cheatsheet

```bash
export RG=reddog-aks-workshop
export LOC=eastus
export SB_NAMESPACE=reddogsbbriar
export VNET_NAME=reddog-vnet
let "randomIdentifier=$RANDOM*$RANDOM"
export SQLSERVER="briar-azuresql-server-$randomIdentifier"
export SQLDB="briarazuresqldb$randomIdentifier"
export SQLLOGIN='azureuser'
export SQLPASSWORD='w@lkingth3d0g'
export STARTIP=67.164.0.0
export ENDIP=67.164.255.255
export REDIS_PASSWD='w@lkingth3d0g'
export REDIS_SERVER='redis-release-master.redis.svc.cluster.local:6379'

SUBNET_ID=$(az network vnet subnet list \
    --resource-group $RG \
    --vnet-name $VNET_NAME \
    --query "[0].id" --output tsv)

az aks create \
    --resource-group $RG \
    --name briar-aks-workshop \
    --network-plugin azure \
    --vnet-subnet-id $SUBNET_ID \
    --docker-bridge-address 172.17.0.1/16 \
    --dns-service-ip 10.2.0.10 \
    --service-cidr 10.2.0.0/24

# Deploy Azure Service Bus
az servicebus namespace create --resource-group $RG --name $SB_NAMESPACE --location $LOC

https://docs.microsoft.com/en-us/azure/service-bus-messaging/service-bus-quickstart-cli

# Deploy Azure SQL, Database, and Firewall rule
az sql server create --name $SQLSERVER --resource-group $RG --location $LOC --admin-user $SQLLOGIN --admin-password $SQLPASSWORD

az sql server firewall-rule create --resource-group $RG --server $SQLSERVER -n AllowYourIp --start-ip-address $STARTIP --end-ip-address $ENDIP
az sql server firewall-rule create --resource-group $RG --server $SQLSERVER -n AllowYourIp --start-ip-address '0.0.0.0' --end-ip-address '0.0.0.0' # for all Azure services

az sql db create --resource-group $RG --server $SQLSERVER --name $SQLDB --edition GeneralPurpose --family Gen5 --capacity 2 --zone-redundant false

https://docs.microsoft.com/en-us/azure/azure-sql/database/scripts/create-and-configure-database-cli?view=azuresql

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
SB_CONNECT_STRING=$(az servicebus namespace authorization-rule keys list --resource-group $RG --namespace-name $SB_NAMESPACE --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)
echo $SB_CONNECT_STRING

    # fix password if needed
    SQLSERVER='briar-azuresql-server-13005848'
    az sql server update --name $SQLSERVER --resource-group $RG --admin-password $SQLPASSWORD

SQL_CONNECTION_STRING="Server=tcp:${SQLSERVER}.database.windows.net,1433;Database=reddog;User ID=${SQLLOGIN};Password=${SQLPASSWORD};Encrypt=true;Connection Timeout=30;"
echo $SQL_CONNECTION_STRING

kubectl create ns reddog
kubectl create secret generic reddog.secretstore \
    -n reddog \
    --from-literal=sb-connect-string=$SB_CONNECT_STRING \
    --from-literal=redis-password=$REDIS_PASSWD \
    --from-literal=redis-server=$REDIS_SERVER \
    --from-literal=reddog-sql=$SQL_CONNECTION_STRING



```