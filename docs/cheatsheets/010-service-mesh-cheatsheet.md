## Service Mesh Cheatsheet

### Install Linkerd

```bash

# install CLI
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install | sh

linkerd version

Client version: stable-2.11.4
Server version: unavailable

# validate AKS cluster
linkerd check --pre

# install the control plane onto your cluster
linkerd install | kubectl apply -f -
linkerd check

# inject linkerd
kubectl get -n reddog deploy -o yaml | linkerd inject - | kubectl apply -f -

# linkerd dashboard
# install the on-cluster metrics stack
linkerd viz install | kubectl apply -f - 

linkerd viz dashboard &

```
