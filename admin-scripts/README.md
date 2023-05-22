# Workshop Setup Scripts

This directory is used for setting up a lab/workshop environment.

What will this deploy:
- Azure Active Directory (AAD) Users (Temporary only for lab/workshop event)
- Resource Groups scoped to each user (e.g. user2@tenant.onmicrosoft.com ---Scoped/RBAC/IAM access to---> RG2)
- Creates a Workshop group to add all users to

## Requirements

1. An Azure Subscription that is setup as a sandbox environment i.e. separate from your corporate Azure Active Directory Tenant, Network and Governance Polices
2. An Azure Active Directory and Azure Subscription Admin User
    - This user should be available during the Lab/Workshop scheduled dates