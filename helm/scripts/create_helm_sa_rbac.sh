#!/usr/bin/env bash

kubectl create -f values/rbac-config.yaml

echo "create tiller namespace"
kubectl create namespace tiller
kubectl create serviceaccount tiller --namespace tiller
kubectl create -f values/role-tiller.yaml
kubectl create -f values/rolebinding-tiller.yaml
