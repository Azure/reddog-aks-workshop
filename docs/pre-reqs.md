
# Subscription Pre-Reqs

In order to run this workshop you should confirm the following pre-requisites.

## Quota

### Cloud Shell

First, if you plan to run this lab via Cloud Shell (https://shell.azure.com) you will be limited to 20 concurrent users per region. When a user first logs into cloud shell they have the 'advanced' shell provisioning option. If they select that option they can choose the target region for their cloud shell storage, which will drive their shell to that region.

### CPU and Public IPs

You need sufficient core and public IP quota for the workshop. You should assume 12 cores per attendee and 6 public IPs. You can use the following commands to check quota, or you can look in the portal.

>**NOTE:** These quotas are per region. If, for some reason, you cannot get sufficient quota in a given region, you can split up attendees across regions.

```bash
SUBSCRIPTION=<Insert Subscription ID>

# Register the Quota provider
az provider register --namespace Microsoft.Quota
az provider show -n Microsoft.Quota

# Set your target region
LOCATION=eastus

# Core Quota Check
###################################
COMPUTE_FAMILY="standardDSv2Family"

CORE_QUOTA=$(az quota show --resource-name $COMPUTE_FAMILY --scope "subscriptions/$SUBSCRIPTION/providers/Microsoft.Compute/locations/$LOCATION" -o tsv --query properties.limit.value)
CORE_USAGE=$(az quota usage show --resource-name $COMPUTE_FAMILY --scope "subscriptions/$SUBSCRIPTION/providers/Microsoft.Compute/locations/$LOCATION" -o tsv --query properties.usages.Value)

echo $COMPUTE_FAMILY usage: $CORE_USAGE/$CORE_QUOTA
###################################

# Public IP Quota Check
###################################
PUBLIC_IP_QUOTA=$(az quota show --resource-name "StandardSkuPublicIpAddresses" --scope "subscriptions/$SUBSCRIPTION/providers/Microsoft.Network/locations/$LOCATION" -o tsv --query properties.limit.value)

PUBLIC_IP_USAGE=$(az quota usage show --resource-name "StandardSkuPublicIpAddresses" --scope "subscriptions/$SUBSCRIPTION/providers/Microsoft.Network/locations/$LOCATION" -o tsv --query properties.usages.Value)

echo Public IPs: $PUBLIC_IP_USAGE/$PUBLIC_IP_QUOTA
###################################
```


## User Rights

In order to run this lab, we recommend all users have 'Contributor' rights on the subscription. However, Contributor isn't sufficient for setting user rights, which is required to set up the managed identity used by the cluster. To address this, you can:

1. Pre-provision the cluster and kubelet managed identities, grant them subscription level contributor rights and have users share those managed identities for cluster creation.
2. Create a custom role with for subscription level 'Role Assignment Write' access and assign all attendees that role. See steps below.

### Role Assignment Write Setup

Create a new file called role-assignment-write.json and paste the following contents, updating with your subscription ID accordingly.

```json
{
"Name": "Role Assignment Write",
"IsCustom": true,
"Description": "Grants rights to assign roles on the subscription",
"Actions": [
    "Microsoft.Authorization/roleAssignments/write"
],
"NotActions": [

],
"AssignableScopes": [
    "/subscriptions/<SUBSCRIPTION_ID>"
]
}
```

Create the custom role and assign it to your user.

>**NOTE:** It may take a few minutes for the custom role to propegate, so if you get an error on assignment, wait a minute and try again.

```bash
# Create the custom role
az role definition create --role-definition @role-assignment-write.json

# Assign the custom role to the user
az role assignment create --assignee <user, group, or service principal> \
--scope "/subscriptions/<SUBSCRIPTION_ID>" \
--role "Role Assignment Write"
```
