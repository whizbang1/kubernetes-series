#!/usr/bin/env bash

echo "preclean"
rm ca.* tiller.* helm.*

echo "set key values"
export SUBJECT="/C=US/ST=Wisconsin/L=Madison/O=ARMS Business Solutions/OU=DEVOPS/CN=armsbusinesssolutions.com"

echo "create certs"
openssl genrsa -out ca.key.pem 4096
openssl req -key ca.key.pem -new -x509 \
    -days 7300 -sha256 \
    -out ca.cert.pem \
    -extensions v3_ca \
    -subj "${SUBJECT}"
# one per tiller host
openssl genrsa -out tiller.key.pem 4096
# one PER user (in this case helm is the user)
openssl genrsa -out helm.key.pem 4096
# create certificates for each of the keys
openssl req \
    -key tiller.key.pem \
    -new \
    -sha256 \
    -out tiller.csr.pem \
    -subj "${SUBJECT}"
openssl req \
    -key helm.key.pem \
    -new \
    -sha256 \
    -out helm.csr.pem \
    -subj "${SUBJECT}"
# sign each of the CSRs with the CA cert
openssl x509 -req \
    -CA ca.cert.pem \
    -CAkey ca.key.pem \
    -CAcreateserial \
    -in tiller.csr.pem \
    -out tiller.cert.pem \
    -days 365 \
    -extfile extfile.cnf
openssl x509 -req \
    -CA ca.cert.pem \
    -CAkey ca.key.pem \
    -CAcreateserial \
    -in helm.csr.pem \
    -out helm.cert.pem \
    -days 365

echo "initialize helm"
helm init \
    --tiller-tls \
    --tiller-tls-cert tiller.cert.pem \
    --tiller-tls-key tiller.key.pem \
    --tiller-tls-verify \
    --tls-ca-cert ca.cert.pem \
    --service-account tiller

helm repo update

echo "verify helm"
kubectl get deploy,svc tiller-deploy -n kube-system
helm ls \
    --tls \
    --tls-ca-cert ca.cert.pem \
    --tls-cert helm.cert.pem \
    --tls-key helm.key.pem

exit 0

echo "backup any old certs in Helm home"
readonly backup_dir=$(helm home)/backup-certs/$(date +%Y%m%d%H%M%S)
mkdir -p "$backup_dir"
cp $(helm home)/*.pem "$backup_dir"

echo "move certs"
# you move them so you don't need to include them with every call to helm
cp ca.cert.pem $(helm home)/ca.pem
cp helm.cert.pem $(helm home)/cert.pem
cp helm.key.pem $(helm home)/key.pem

echo "verify security"
helm ls --tls
