## CI/CD and GitOps Cheatsheet

### Fork the GitHub Repo

Fork this repo into your GitHub account: https://github.com/CloudNativeGBB/reddog-code

```bash
# clone the repo into your local environment
git clone https://github.com/chzbrgr71/reddog-code reddog-code-chzbrgr71

mkdir -p .github/workflows
```

### Add a GitHub Action

Again, in this workshop, you could just package and deploy a single service for simplicity. It may make sense to create separate workflows for each service.

Note that we are using the Azure Container Registry for access control here. This is a good discussion topic as there are other ways to approach this.

* Configure the Admin Account in your Azure Container Registry

    ![ACR Admin Account](../assets/acr-admin-account.png)

* Create secrets in Github for the above account

    ![GitHub Secrets](../assets/github-repo-secrets.png)

    * ACR_ENDPOINT (the login server, eg - `briarreddogacr.azurecr.io`)
    * ACR_USERNAME
    * ACR_PASSWORD

* Create a workflow file called: `./.github/workflows/package-order-service.yml`
    * The workflow file should look like [package-order-service.yml](./cicd/package-order-service.yml)







