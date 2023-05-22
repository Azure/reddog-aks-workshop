# Basics of Helm and Kustomize

## Overview

When you start working on large scale application deployments across serveral environments, you'll quickly find that basic Kubernetes manifest files don't provide all the functionality you need to simplify those deployments. For example, the ability to parameterize, or override, certain details based on the target environment. This is were the Helm and Kustomize projects can help you out. 

In this lab we'll walk through the most basic useage of these tools. There is A LOT more you can do with thes, but we'll leave that to the upstream project documentation linked below:

[Helm](https://helm.sh/)
[Kustomize](https://kustomize.io/)

## Helm

First lets take a look at the basics of Helm. First, Helm does have it's own command line interface that you'll need to install. You can see the install steps [here](https://helm.sh/docs/intro/install/). Fortunately, if you're using the Azure Cloud Shell, Helm is already installed for you.

First lets see how you install other people charts into your cluster. To do this, we'll add a helm chart repository to our local repos list and then deploy the chart.

```bash
# Add the repo
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update your local repos
helm repo update 

# Look at the charts in the repo
helm search repo bitnami

# Deploy mysql from the repo
helm install bitnami/mysql --generate-name

# Sample Output
NAME: mysql-1684783619
LAST DEPLOYED: Mon May 22 15:26:59 2023
NAMESPACE: lab
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
CHART NAME: mysql
CHART VERSION: 9.10.1
APP VERSION: 8.0.33

** Please be patient while the chart is being deployed **

Tip:

  Watch the deployment status using the command: kubectl get pods -w --namespace lab

Services:

  echo Primary: mysql-1684783619.lab.svc.cluster.local:3306

Execute the following to get the administrator credentials:

  echo Username: root
  MYSQL_ROOT_PASSWORD=$(kubectl get secret --namespace lab mysql-1684783619 -o jsonpath="{.data.mysql-root-password}" | base64 -d)

To connect to your database:

  1. Run a pod that you can use as a client:

      kubectl run mysql-1684783619-client --rm --tty -i --restart='Never' --image  docker.io/bitnami/mysql:8.0.33-debian-11-r12 --namespace lab --env MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD --command -- bash

  2. To connect to primary service (read/write):

      mysql -h mysql-1684783619.lab.svc.cluster.local -uroot -p"$MYSQL_ROOT_PASSWORD"
```

Take a look at what was deployed.

```bash
# List deployed helm charts for all namespaces (i.e. -A)
helm ls -A

# Sample Output
NAME                    NAMESPACE       REVISION        UPDATED                                 STATUS          CHART           APP VERSION
mysql-1684783619        lab             1               2023-05-22 15:26:59.89227 -0400 EDT     deployed        mysql-9.10.1    8.0.33     

# Get all
kubectl get all

# Sample Output
NAME                     READY   STATUS    RESTARTS   AGE
pod/mysql-1684783619-0   0/1     Running   0          73s

NAME                                TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
service/mysql-1684783619            ClusterIP   10.0.184.150   <none>        3306/TCP   73s
service/mysql-1684783619-headless   ClusterIP   None           <none>        3306/TCP   73s

NAME                                READY   AGE
statefulset.apps/mysql-1684783619   0/1     73s
```

Now you can delete this release.

```bash
# Get the release name
helm ls

# Helm Delete the release
# Update the below with your release name, obviously
helm delete mysql-1684783619
```

Now lets create our own chart.

```bash
# Scaffold out the chart
helm create sample

# Browse to the chart folder
cd sample
```

You can take a few minutes to browse around the files in the sample chart to understand the structure, checking out the helm docs while you look. We'll mostly be concerned with the values file and the files in the templates folder right now.

Now that you're more familiar with the chart folder, we'll delete some files and create some fresh.

```bash
# Delete unneeded files
rm templates/*.yaml
rm -rf templates/tests
rm templates/NOTES.txt
```

Now create the following new files.

**templates/deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:1.23.4
        name: nginx
```

**templates/service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
spec:
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  type: LoadBalancer
```

You how have a helm chart. Lets deploy it.

```bash
# Move up a directory so you can see the sample chart folder
cd ..

# Install the chart with helm
helm install sample-chart sample

# Sample Output
NAME: sample-chart
LAST DEPLOYED: Mon May 22 15:41:43 2023
NAMESPACE: lab
STATUS: deployed
REVISION: 1
TEST SUITE: None

# CHeck the Deployment
kubectl get svc,deploy,pods

# Sample Output
NAME                TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)        AGE
service/nginx-svc   LoadBalancer   10.0.221.105   52.226.241.176   80:32410/TCP   27s

NAME                    READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/nginx   3/3     3            3           27s

NAME                         READY   STATUS    RESTARTS   AGE
pod/nginx-7467c7b65c-5j2k9   1/1     Running   0          27s
pod/nginx-7467c7b65c-mgdsn   1/1     Running   0          27s
pod/nginx-7467c7b65c-zl4b4   1/1     Running   0          27s
```

Now lets use a parameter in the chart. Edit the 'deployment.yaml' in your 'templates folder to parameterize the image tag, as shown below.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: nginx
  name: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - image: nginx:{{ .Values.deployment.imagetag }}
        name: nginx
```

Now upgrade the deployment, setting a new image tag.

```bash
# Run the helm upgrade
helm upgrade sample-chart --set deployment.imagetag=1.24 sample
```

You should see the deployment update, and if you check your image tags on your pod, you'll see the version is now 1.24.

Alternatively, to using the '--set' flag, you can update the values.yaml file. Open the values.yaml file and update so that it looks like the following

```yaml
deployment:
  imagetag: 1.24
```

Now roll back the last release and we'll upgrade, this time using the values file.

```bash
# Rollback the helm release
helm rollback sample-chart

# At this point you can check the pod image tag version, and you should see 1.23.4

# Now lets completely delete the helm release.
helm delete sample-chart

# Finally, lets install the helm chart using the values file.
# Again, this is from the directory above the chart
helm install sample-chart -f sample/values.yaml sample

# Again, if you describe one of the pods, you'll see its running image tag 1.24, which matches what we had in the values.yaml
```




