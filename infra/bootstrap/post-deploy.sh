#!/bin/bash
set -e
echo "=== Post-Deploy Setup ==="

# 1. Create gp3 StorageClass
echo "Creating gp3 StorageClass..."
kubectl apply -f - <<EOF
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
provisioner: ebs.csi.aws.com
volumeBindingMode: WaitForFirstConsumer
parameters:
  type: gp3
  encrypted: "true"
EOF

# 2. Create namespaces
echo "Creating namespaces..."
kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace gitea --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -

# 3. ArgoCD repo secret
read -s -p "Enter GitHub PAT (Contents: Read permission): " GITHUB_PAT
echo
kubectl create secret generic argocd-repo-secret \
  --from-literal=type=git \
  --from-literal=url=https://github.com/hasanenv/gitea-eks-platform \
  --from-literal=password="$GITHUB_PAT" \
  --from-literal=username=hasanenv \
  -n argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl label secret argocd-repo-secret -n argocd argocd.argoproj.io/secret-type=repository --overwrite

# 4. Cloudflare API token (used by ExternalDNS and cert-manager)
read -s -p "Enter Cloudflare API token: " CF_TOKEN
echo
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="$CF_TOKEN" \
  -n external-dns --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic cloudflare-api-token \
  --from-literal=api-token="$CF_TOKEN" \
  -n cert-manager --dry-run=client -o yaml | kubectl apply -f -

# 5. RDS DB password
read -s -p "Enter RDS DB password: " DB_PASSWORD
echo
kubectl create secret generic gitea-db-secret \
  --from-literal=password="$DB_PASSWORD" \
  -n gitea --dry-run=client -o yaml | kubectl apply -f -

# 6. Gitea admin credentials
read -p "Enter Gitea admin username (default: gitea_admin): " GITEA_USER
GITEA_USER=${GITEA_USER:-gitea_admin}
read -s -p "Enter Gitea admin password: " GITEA_PASS
echo
kubectl create secret generic gitea-admin-secret \
  --from-literal=username="$GITEA_USER" \
  --from-literal=password="$GITEA_PASS" \
  -n gitea --dry-run=client -o yaml | kubectl apply -f -

# 7. Grafana admin credentials
read -s -p "Enter Grafana admin password: " GRAFANA_PASS
echo
kubectl create secret generic grafana-admin-secret \
  --from-literal=admin-user=admin \
  --from-literal=admin-password="$GRAFANA_PASS" \
  -n monitoring --dry-run=client -o yaml | kubectl apply -f -

# 8. Apply ClusterIssuer
echo "Waiting for cert-manager to be ready..."
kubectl wait --for=condition=available deployment/cert-manager -n cert-manager --timeout=300s
echo "Applying ClusterIssuer..."
kubectl apply -f infra/kubernetes/platform/cert-manager/cluster-issuer.yaml

echo "=== Post-deploy setup complete ==="
echo "Setup complete. Watch ArgoCD sync the applications in the 'argocd' namespace to deploy the platform components."