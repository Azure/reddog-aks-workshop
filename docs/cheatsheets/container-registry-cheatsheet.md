## Image Management / Container Registry Cheatsheet

```bash
RG=RedDogAKSWorkshop
LOC=eastus
ACRNAME=briarreddogacr # must be globally unique
KUBELET_IDENTITY_NAME=kubeletidentity #created in a prior step

# create the ACR
az acr create --resource-group $RG --name $ACRNAME --sku Standard

# setup permissions for managed identity
KUBELET_IDENTITY_OBJID=$(az identity show -g $RG -n $KUBELET_IDENTITY_NAME -o tsv --query principalId)
ACRID=$(az acr show --resource-group $RG --name $ACRNAME --query id --output tsv)

az role assignment create --assignee-object-id $KUBELET_IDENTITY_OBJID --scope $ACRID --role acrpull

# manually push copies of the Red Dog services
docker pull ghcr.io/azure/reddog-retail-demo/reddog-retail-accounting-service:latest

az acr login -n $ACRNAME

docker tag ghcr.io/azure/reddog-retail-demo/reddog-retail-accounting-service:latest $ACRNAME.azurecr.io/reddog-retail-demo/reddog-retail-accounting-service:latest 

docker push $ACRNAME.azurecr.io/reddog-retail-demo/reddog-retail-accounting-service:latest 

# update manifest and test image deployment
# Eg: $ACRNAME.azurecr.io/reddog-retail-demo/reddog-retail-accounting-service:latest

kubectl apply -f ./manifests/workshop-cheatsheet/reddog-services/accounting-service.yaml

# container Image Scanning - Quick local scan (open source)

docker run --rm \
--volume /var/run/docker.sock:/var/run/docker.sock \
--name Grype anchore/grype:latest \
briarreddogacrnew.azurecr.io/reddog-retail-demo/reddog-retail-accounting-service:latest

# container Image Scanning - Microsoft Defender for Containers
https://docs.microsoft.com/en-us/azure/defender-for-cloud/defender-for-containers-enable



```
