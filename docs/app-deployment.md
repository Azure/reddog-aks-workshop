# Application Manifests and Deployment

## App Architecture

![Architecture diagram](./assets/reddog_architecture.jpg)

Red Dog Overview:

* Red Dog is a series of microservices that support a ficticious Retail Company 
* Each microservice runs as a container and is planned for Kubernetes in Azure
* This is an event driven architecture using Azure Service Bus for pub/sub
* Redis Cache is used to store state for some of the services
* Azure SQL is used to store the full order history
* The UI Dashboard shows the current activity of the business
* There are 2 background services used to simulate activity. Virtual Customer creates orders and Virtual Worker processes and fullfills orders
* The services use the Distributed Application Runtime [(Dapr)](http://dapr.io) as a sidecar for various actions

## Application Pre-requisites

Deploy the following before deploying Red Dog.

* Azure Service Bus (Standard)
* SQL Azure
* Redis Cache (deploy in your AKS cluster via Helm)
* Dapr https://docs.dapr.io/operations/hosting/kubernetes/kubernetes-deploy/#install-with-helm-advanced

## Kubernetes Secrets

For simplicity, we will just use Kubernetes secrets to allow Red Dog services to connect to the above resources. Longer term, we would want to use Azure Key Vault for secure storage. This will be covered in a future lab.

* Create a secret called `reddog.blah` and add the following:
    * Service Bus connection info
    * SQL id/password
    * Redis

> Note: You can generally get the password/creds from the Azure CLI. Example: 

```bash
SB_CONNECT_STRING=$(az servicebus namespace authorization-rule keys list --resource-group $RG --namespace-name $SB_NAMESPACE --name RootManageSharedAccessKey --query primaryConnectionString --output tsv)
```    

## Application Requirements

The YAML files needed to deploy Red Dog are provided in this repo (manifests folder).

* Everything should be deployed into a namespace called `reddog` 
* Resource requests/limits are required and must be added to the deployment manifests. Think about total cluster resources and ensure that everything can be run in the cluster

> For the purposes of this workshop, you can just add these requests/limits to just one of the services

## Tasks:

1. Deploy the above Pre-requisites in your AKS cluster
2. Create a secret in your AKS cluster with the necessary creds
3. Update the Red Dog manifests and deploy everything into your AKS cluster

   > **Warning**
   > The Dapr components (CRD's) should be deployed before the applications themselves








