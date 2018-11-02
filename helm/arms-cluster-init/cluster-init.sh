# !/bin/bash

################
# parameters
################
project=$1
region=$2
cluster=$3
loadBalancerIP=$4
loadBalancerType=$5
defaultDomain=$6
helmHistory=$7

# Setup kube context and use it
gcloud container clusters get-credentials $cluster --project=$project --region=$region
kubectl config use-context gke_${project}_${region}_${cluster}

# Setup the tiller service account and role bindings
kubectl apply \
 --filename=helm-tiller.yaml

# Initialize Helm using TLS
helm init \
 --service-account tiller \
 --tiller-tls \
 --tiller-tls-verify \
 --tiller-tls-cert tiller.cert.pem \
 --tiller-tls-key tiller.key.pem \
 --tiller-namespace=helm \
 --tls-ca-cert ca.cert.pem \
 --history-max=$helmHistory \
 --wait

# Add the ABS Artifactory Helm Repo
helm repo add abs https://repo.pg-dev.net/artifactory/charts
helm repo update

# Install the namespace-init chart to create all the ABS namespaces
helm upgrade \
 --install \
 --tls \
 --wait \
 --namespace=default \
 --tiller-namespace=helm \
 namespace-init abs/namespace-init

# Install the hostfile-ds chart to add all necessary hostfile entries to the cluster nodes
 helm upgrade \
 --install \
 --tls \
 --wait \
 --namespace=infrastructure \
 --tiller-namespace=helm \
 hostfile-ds abs/hostfile-ds

# Create the ingress-values.yaml file to be used by the nginx-ingress chart
printf "defaultDomain: \"$defaultDomain\"\n" > ingress-values.yaml
printf "cert:\n  tls.crt: |\n" >> ingress-values.yaml
sed -e 's/^/    /' ingress.cert.pem >> ingress-values.yaml
printf "\n  tls.key: |\n" >> ingress-values.yaml
sed -e 's/^/    /' ingress.key.pem >> ingress-values.yaml

printf "nginx-ingress:\n  controller:\n    extraArgs:\n      default-ssl-certificate: \"infrastructure/$defaultDomain\"\n    service:\n      loadBalancerIP: \"$loadBalancerIP\"\n" >> ingress-values.yaml

if [ "$loadBalancerType" = "internal" ]; then
  printf "      annotations:\n        cloud.google.com/load-balancer-type: \"Internal\""  >> ingress-values.yaml
fi

# Install the nginx-ingress chart to add ABS nginx-ingress controller
 helm upgrade \
 --install \
 --tls \
 --wait \
 --values=ingress-values.yaml \
 --namespace=nginx-ingress \
 --tiller-namespace=helm \
 nginx-ingress abs/nginx-ingress 


# Apply the changes to kube dns to use our IPA server for our domains
if [ -f kube-dns.yaml ]; then
  kubectl -n kube-system apply -f kube-dns.yaml
fi

# Install role bindings so jenkins can interact with tiller
 helm upgrade \
 --install \
 --tls \
 --wait \
 --set project=$project \
 --namespace=helm \
 --tiller-namespace=helm \
 helm-client-init abs/helm-client-init

# Cleanup
rm -f ingress-values.yaml
