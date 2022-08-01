## Egress Lockdown Cheatsheet

### Create the Azure Firewall
```bash
# Create Azure Firewall Public IP
az network public-ip create -g $RG -n azfirewall-ip --sku "Standard"

# Create Azure Firewall
az extension add --name azure-firewall
FIREWALLNAME=reddog-egress
az network firewall create -g $RG -n $FIREWALLNAME --enable-dns-proxy true

# Configure Firewall IP Config
az network firewall ip-config create -g $RG -f $FIREWALLNAME -n aks-firewallconfig --public-ip-address azfirewall-ip --vnet-name $VNET_NAME

# Capture Firewall IP Address for Later Use
FWPUBLIC_IP=$(az network public-ip show -g $RG -n azfirewall-ip --query "ipAddress" -o tsv)
FWPRIVATE_IP=$(az network firewall show -g $RG -n $FIREWALLNAME --query "ipConfigurations[0].privateIpAddress" -o tsv)

az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwnr' \
-n 'apiudp' \
--protocols 'UDP' \
--source-addresses '*' \
--destination-addresses "AzureCloud.$LOC" \
--destination-ports 1194 --action allow --priority 100

az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwnr' \
-n 'apitcp' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses "AzureCloud.$LOC" \
--destination-ports 9000

az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwnr' \
-n 'time' \
--protocols 'UDP' \
--source-addresses '*' \
--destination-fqdns 'ntp.ubuntu.com' \
--destination-ports 123

# Add FW Application Rules
az network firewall application-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwar' \
-n 'fqdn' \
--source-addresses '*' \
--protocols 'http=80' 'https=443' \
--fqdn-tags "AzureKubernetesService" \
--action allow --priority 100

```

### Create the Azure Route Table

```bash
# Create Route Table
az network route-table create \
-g $RG \
-n aksdefaultroutes

# Create Route
az network route-table route create \
-g $RG \
--route-table-name aksdefaultroutes \
-n firewall-route \
--address-prefix 0.0.0.0/0 \
--next-hop-type VirtualAppliance \
--next-hop-ip-address $FWPRIVATE_IP

az network route-table route create \
-g $RG \
--route-table-name aksdefaultroutes \
-n internet-route \
--address-prefix $FWPUBLIC_IP/32 \
--next-hop-type Internet

# Associate Route Table to AKS Subnet
az network vnet subnet update \
-g $RG \
--vnet-name $VNET_NAME \
-n aks \
--route-table aksdefaultroutes
```
