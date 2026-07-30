#!/bin/bash

aws eks update-kubeconfig --name gitea-eks-cluster --region eu-west-2

kubectl create namespace argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update
helm install argocd argo/argo-cd \
  --namespace argocd \
  --version 10.2.1 \
  -f "$(dirname "$0")/values.yaml"

kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=300s

kubectl apply -f "$(dirname "$0")/../kubernetes/platform/argocd/"