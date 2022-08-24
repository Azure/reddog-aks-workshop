## Monitoring Cheatsheet

#### _Azure Monitor_

*Create a Log Analytics Workspace*
```bash
WORKSPACEID=$(az monitor \
log-analytics workspace create \
-g CLUSTER-RG \
-n WORKSPACE-NAME \
| jq '.id')
```

*Enable Azure Container Insights on your cluster*
```bash
az aks enable-addons -a monitoring \
-n CLUSTERNAME \
-g CLUSTER-RG \ 
--workspace-resource-id $WORKSPACEID
```



#### _Prometheus & Grafana_

*Install Kube Prometheus*

The first step in getting our Windows node metrics into Prometheus and Grafana is to install the Kube Prometheus project into our cluster. We'll do this using the manifests published by the Kube Prometheus project.

*Clone the Kube Prometheus repository*

    ```bash
    git clone https://github.com/prometheus-operator/kube-prometheus.git
    ```

To make sure you're running the right version, check the [version compatibility table](https://github.com/prometheus-operator/kube-prometheus#compatibility) and then git checkout the right branch for your specific Kubernetes version. 

    ```bash
    # Looking at the compatibility matrix I can see that Kubernetes 1.23 is compatible with Kube Prometheus release-0.10

    # Checkout the release-0.10 branch
    git checkout release-0.10
    Switched to branch 'release-0.10'
    Your branch is up to date with 'origin/release-0.10'.
    ```

Now we can follow the documented installation steps from the Kube Prometheus project

    ```bash
    # Create the namespace and CRDs, and then wait for them to be available before creating the remaining resources
    kubectl apply --server-side -f manifests/setup
    until kubectl get servicemonitors --all-namespaces ; do date; sleep 1; echo ""; done
    kubectl apply -f manifests/
    ```

Check the status of your deployment

    ```bash
    kubectl get svc,pods -n monitoring
    NAME                            TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
    service/alertmanager-main       ClusterIP   10.0.208.250   <none>        9093/TCP,8080/TCP            4h34m
    service/alertmanager-operated   ClusterIP   None           <none>        9093/TCP,9094/TCP,9094/UDP   4h30m
    service/blackbox-exporter       ClusterIP   10.0.222.215   <none>        9115/TCP,19115/TCP           4h34m
    service/grafana                 ClusterIP   10.0.143.100   <none>        3000/TCP                     4h34m
    service/kube-state-metrics      ClusterIP   None           <none>        8443/TCP,9443/TCP            4h34m
    service/node-exporter           ClusterIP   None           <none>        9100/TCP                     4h34m
    service/prometheus-adapter      ClusterIP   10.0.238.32    <none>        443/TCP                      4h33m
    service/prometheus-k8s          ClusterIP   10.0.47.227    <none>        9090/TCP,8080/TCP            4h33m
    service/prometheus-operated     ClusterIP   None           <none>        9090/TCP                     4h30m
    service/prometheus-operator     ClusterIP   None           <none>        8443/TCP                     4h33m

    NAME                                       READY   STATUS    RESTARTS   AGE
    pod/alertmanager-main-0                    2/2     Running   0          4h30m
    pod/alertmanager-main-1                    2/2     Running   0          4h30m
    pod/alertmanager-main-2                    2/2     Running   0          4h30m
    pod/blackbox-exporter-6b79c4588b-dwkpf     3/3     Running   0          4h34m
    pod/grafana-7fd69887fb-xgqbx               1/1     Running   0          4h34m
    pod/kube-state-metrics-55f67795cd-hfshk    3/3     Running   0          4h34m
    pod/node-exporter-698pm                    2/2     Running   0          4h34m
    pod/node-exporter-rpxg7                    2/2     Running   0          4h30m
    pod/prometheus-adapter-85664b6b74-cwm6n    1/1     Running   0          4h33m
    pod/prometheus-adapter-85664b6b74-k7tnb    1/1     Running   0          4h33m
    pod/prometheus-k8s-0                       2/2     Running   0          4h30m
    pod/prometheus-k8s-1                       2/2     Running   0          4h30m
    pod/prometheus-operator-6dc9f66cb7-8wc6p   2/2     Running   0          4h33m
    ```

Now lets test connectivity to the Prometheus and Grafana dashboards. They're deployed as 'Cluster IP' services, so we can either modify them to be type 'LoadBalancer' or we can use a port-forward. We'll port-forward for now.

    ```bash
    kubectl port-forward service/grafana -n monitoring 3000:3000
    Forwarding from 127.0.0.1:3000 -> 3000
    Forwarding from [::1]:3000 -> 3000
    ```

Navigate your browser to http://localhost:3000
   
Enter the userid and password (admin:admin) and then follow the prompts to reset the admin password


Click on the '/Node Exporter/USE Method/Cluster' dashboard, and notice that the data is only sourced from the linux nodes









