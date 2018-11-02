# cluster-init
This project contains scripts and resource definitions to bootstrap a kubernetes cluster in GKE.

## Prerequisites & assumptions

### Client Assumptions
This install assumes the client machine running the `cluster-init` script has the required tools installed and configured:
* **[Google Cloud SDK](https://cloud.google.com/sdk/install)** - to setup credentials to the GKE cluster
* **[kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)** - To setup prequisites to helm.
* **[helm](https://docs.helm.sh/using_helm/#installing-helm)** - to install the charts

See the client-init git repo for scripts to get your local machine setup

### Server Assumptions
* This script assumes the VPC, Networking, and Google Kubernetes Engine Cluster has already been provisioned via terraform or some other mechanism.
* An IP Address has been reserved that will be used by the nginx-controller


## Required Downloads
In order for the `cluster-init` script to fully intialize the cluster, the following files are required to be downloaded separately into the current working directory
* Tiller - these files can be found in PMP underneath the Helm CA Resource
    * **ca.cert.pem** - the Certificate Authority Certificate
    * **tiller.cert.pem** - the Tiller (server side) Certificate 
    * **tiller.key.pem** - the Tiller (server side) private key
* Ingress - these files currently live on our Google Site
    * **ingress.cert.pem** - the Certificate for the Ingress Controller (cert for *.dev-armsbusinesssolutions.com, *.armsbusinesssolutions.eu, etc)
    * **ingress.key.pem** - the private key for the Ingress Controller
* DNS - there must be a file named **kube-dns.yaml** in your working directory with the override configuration

## Usage
To intialize the cluster, run the following command
```
./cluster-init.sh <project> <region> <cluster-name> <load-balancer-ip> <load-balancer-type>
```
where
* **project** = the Project ID in GCP (i.e. us-dev-213417)
* **region** = the region where the cluster resides in GCP (i.e. us-central1)
* **cluster-name** = the name of the Cluster in GCP defaults to cluster-1
* **load-balancer-ip** = the IP address of loadbalancer
* **load-balancer-type** = the type of loadbalancer: one of "internal" or "external"
* **defaultDomain** = the domain that will use the default SSL cert (and key)
* **helmHistory** = the max number of releases to keep 
### Examples

#### US Dev
```
./cluster-init.sh us-dev-213417 us-central1 cluster-1 10.64.4.8 internal dev.arms-dev.net 2
```

#### EU QA
```
./cluster-init.sh eu-qa-213614 europe-west2 cluster-1 192.168.0.1 external int.arms-dev.net 10
```
