#!/usr/bin/env bash
set -e

# https://argo-cd.readthedocs.io/en/stable/user-guide/private-repositories/#access-token
# REPOSITORY_URL=""
# REPOSITORY_USERNAME=""
# REPOSITORY_PAT_TOKEN=""


# https://argo-cd.readthedocs.io/en/stable/getting_started/
# https://github.com/argoproj/argocd-example-apps

# https://argo-cd.readthedocs.io/en/stable/getting_started/
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Install argocd cli
brew install argocd

# Service Type Load Balancer for ArgoCD UI
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "LoadBalancer"}}'
sleep 60

# Port Forwarding to Service (keep running in background, suppress all output)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &>/dev/null &
argo_api_server="127.0.0.1:8080"
sleep 10

# Get initial password
argo_initial_password=$(argocd admin initial-password -n argocd | head -1)

# Reset initial password
argocd login $argo_api_server --insecure --username admin --password $argo_initial_password
# argocd account update-password --account admin
sleep 10

# Get cluster contexts
kubectl config get-contexts -o name

# Set context for argocd
argocd cluster add minikube -y

# Stop kubectl forwarding
kill %1

# Configure access to repository
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: "$REPOSITORY_NAME"
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  url: "$REPOSITORY_URL"
  username: "$REPOSITORY_USERNAME"
  password: "$REPOSITORY_PAT_TOKEN"
EOF

