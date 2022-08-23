## Egress Lockdown Cheatsheet

In egress lockdown, you were given the following requirements:

* Azure Firewall should be used to control outbound network traffic
* The Azure Firewall should have DNS Proxy enabled
* The subnet which will host the Azure Kubernetes Service cluster should force internet traffic (default route 0.0.0.0/0) to the Azure Firewall
* The Azure Firewall should allow the following list of IPs and FQDNs, as described in the [AKS Egress Lockdown](https://docs.microsoft.com/en-us/azure/aks/limit-egress-traffic) doc

    |Address |Protocol |Ports |
    | ---- | ---- | ---- |
    |AzureCloud.\<region\>|UDP|1194|
    |AzureCloud.\<region\>|TCP|9000, 443|
    |ntp.ubuntu.com|UDP|123|
    |AzureKubernetesService|TCP|80, 443|

You were asked to complete the following tasks:

1. Create a subnet for the Azure Firewall
2. Create and configure the Azure Firewall
3. Create and configure the Azure Route table

### Create a subnet for the Azure Firewall

First we need to create a subnet where we'll deploy the Azure Firewall.

> **Note**
> The subnet must be at least a /26 and must be named AzureFirewallSubnet

```bash
RG=RedDogAKSWorkshop
VNET_NAME=reddog-vnet

# Adding a subnet for the Azure Firewall
az network vnet subnet create \
--resource-group $RG \
--vnet-name $VNET_NAME \
--name AzureFirewallSubnet \
--address-prefix 10.140.1.0/24
```

### Create the Azure Firewall

To create an Azure Firewall, we create a public IP and the firewall, and then link the two together.

```bash
# Create Azure Firewall Public IP
az network public-ip create -g $RG -n azfirewall-ip --sku "Standard"

# Create Azure Firewall
az extension add --name azure-firewall
FIREWALLNAME=reddog-egress
az network firewall create -g $RG -n $FIREWALLNAME --enable-dns-proxy true

# Configure Firewall IP Config
az network firewall ip-config create -g $RG -f $FIREWALLNAME -n aks-firewallconfig --public-ip-address azfirewall-ip --vnet-name $VNET_NAME

```

### Create the firewall rules

Using the table provided in the requirements, we create the following firewall rules:

```bash
az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwnr' \
-n 'aksapiudp' \
--protocols 'UDP' \
--source-addresses '*' \
--destination-addresses "AzureCloud.$LOC" \
--destination-ports 1194 --action allow --priority 100

az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwnr' \
-n 'aksapitcp' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses "AzureCloud.$LOC" \
--destination-ports 9000 443

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

Now that the firewall is created, we can create an Azure Route Table which will ensure that all Internet bound traffic from the AKS subnet gets sent to the Azure Firewall.

```bash
# First get the public and private IP of the firewall for the routing rules
FWPUBLIC_IP=$(az network public-ip show -g $RG -n azfirewall-ip --query "ipAddress" -o tsv)
FWPRIVATE_IP=$(az network firewall show -g $RG -n $FIREWALLNAME --query "ipConfigurations[0].privateIpAddress" -o tsv)

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

<HR>
<BR>

## Extra Firewall Rules

As you perform other actions you may find that images are blocked, or you have other issue. Here are a few known firewall rules you may add along the way.

### Docker Hub Rules

```bash
az network firewall application-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwdocker' \
-n 'docker' \
--source-addresses '*' \
--protocols 'http=80' 'https=443' \
--target-fqdns auth.docker.io registry-1.docker.io index.docker.io dseasb33srnrn.cloudfront.net production.cloudflare.docker.com \
--action allow --priority 101
```

### Ubuntu Apt
```bash
az network firewall application-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwnr' \
-n 'ubuntu-apt' \
--source-addresses '*' \
--protocols 'http=80' 'https=443' \
--target-fqdns archive.ubuntu.com security.ubuntu.com \
--action allow --priority 102
```

### Azure Marketplace

```bash
az network firewall application-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'azrmktplc' \
-n 'azrmarketplace' \
--source-addresses '*' \
--protocols 'http=80' 'https=443' \
--target-fqdns marketplace.azurecr.io marketplaceeush.cdn.azcr.io \
--action allow --priority 103
```

### GitHub Registry (RedDog Registry)

```bash
az network firewall application-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'githubcr' \
-n 'github' \
--source-addresses '*' \
--protocols 'http=80' 'https=443' \
--target-fqdns ghcr.io pkg-containers.githubusercontent.com \
--action allow --priority 104
```


### K8s Registry (Ingress Nginx Registry)

```bash
az network firewall application-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'k8scr' \
-n 'k8scr' \
--source-addresses '*' \
--protocols 'http=80' 'https=443' \
--target-fqdns registry.k8s.io k8s.gcr.io storage.googleapis.com \
--action allow --priority 105
```

### Service Bus Endpoint

```bash
az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwnr' \
-n 'svcbus' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses  "ServiceBus" \
--destination-ports 5671
```

### SQL Server Endpoint

```bash
az network firewall network-rule create \
-g $RG \
-f $FIREWALLNAME \
--collection-name 'aksfwnr' \
-n 'sqltcp' \
--protocols 'TCP' \
--source-addresses '*' \
--destination-addresses  "Sql" \
--destination-ports 1433 11000-11999
```

