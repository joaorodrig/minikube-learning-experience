#!/usr/bin/env bash
set -e

# REPOSITORY_URL=""
# REPOSITORY_NAME=""
# REPOSITORY_USERNAME=""
# REPOSITORY_REPO_TOKEN=""

# Install argocd cli
brew install argocd




# ----------------------------------------------------------------------------------------------------------------- #
# Create the NFS Host machine
vagrant up minikube-nfs-1

# Get the machine IP address (eth0 is vagrant default, eth1 is explicit kvm network)
STORAGE_HOST_IP=$(vagrant ssh -c "ip address show eth1 | grep 'inet ' | sed -e 's/^.*inet //' -e 's/\/.*$//' | tr -d '\n'")

# ----------------------------------------------------------------------------------------------------------------- #



# ----------------------------------------------------------------------------------------------------------------- #
# Install minikube ------------------------------------------------------------------------------------------------ #

# Install / update minikube
wget https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube-linux-amd64
sudo mv minikube-linux-amd64 /usr/local/bin/minikube

# Install / update kvm2 driver for minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/docker-machine-driver-kvm2
chmod +x docker-machine-driver-kvm2
sudo mv docker-machine-driver-kvm2 /usr/local/bin/

# Start / stop minikube (can be seen in libvirtd client)
minikube delete || true
minikube start --vm-driver kvm2 --insecure-registry="docker-registry.vlab:5000"
minikube stop # Initial run may default to docker and ignore kvm2 sdriver


# Add local records to Minikube Host
mkdir -p ~/.minikube/files/etc
cat > ~/.minikube/files/etc/hosts <<EOF
127.0.0.1 localhost
${STORAGE_HOST_IP} docker-registry.vlab
${STORAGE_HOST_IP} nfs-storage.vlab
EOF

# Start minikube
minikube start
# ----------------------------------------------------------------------------------------------------------------- #



# ----------------------------------------------------------------------------------------------------------------- #
# Add local records  CoreDNS 

# CoreDNS
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30
        loop
        reload
        loadbalance
        hosts {
          ${STORAGE_HOST_IP} docker-registry.vlab
          ${STORAGE_HOST_IP} nfs-storage.vlab
          fallthrough
        }
    }
EOF

# ----------------------------------------------------------------------------------------------------------------- #



# ----------------------------------------------------------------------------------------------------------------- #
# Configure Default Storage Class (NFS) --------------------------------------------------------------------------- #
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm repo update
helm upgrade --install nfs-subdir-external-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=nfs-storage.vlab \
  --set nfs.path=/mnt/nfs_share/k8s-volumes \
  --set storageClass.name=nfs-storage-class
kubectl patch storageclass nfs-storage-class -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

# ----------------------------------------------------------------------------------------------------------------- #



# ----------------------------------------------------------------------------------------------------------------- #
# Install GitHub runner in minikube ------------------------------------------------------------------------------- #
# https://blog.opstree.com/2023/04/18/github-self-hosted-runner-on-kubernetes/
# https://artifacthub.io/packages/helm/cert-manager/cert-manager
github_actions_namespace="github-actions-runner"
cert_manager_version="v1.11.1"
kubectl create namespace $github_actions_namespace --dry-run=client -o yaml | kubectl apply -f -

# Install and configure cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/${cert_manager_version}/cert-manager.crds.yaml
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install my-release -n $github_actions_namespace --version ${cert_manager_version} jetstack/cert-manager
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: ca-issuer
  namespace: $github_actions_namespace
spec:
  ca:
    secretName: ca-key-pair
EOF

# Creating secret for ARC, so that it can register runners on github
kubectl create secret generic controller-manager -n $github_actions_namespace --from-literal=github_token=$REPOSITORY_REPO_TOKEN --dry-run=client -o yaml | kubectl apply -f -

# Adding Helm Repo of ARC
helm repo add actions-runner-controller https://actions-runner-controller.github.io/actions-runner-controller
helm repo update

# Installing ARC
helm upgrade --install -n $github_actions_namespace --create-namespace --wait actions-runner-controller  actions-runner-controller/actions-runner-controller --set syncPeriod=1m
kubectl -n $github_actions_namespace get all

# Create GitHub runners
kubectl apply -f - <<EOF
apiVersion: actions.summerwind.dev/v1alpha1
kind: RunnerDeployment
metadata:
  name: k8s-action-runner
  namespace: $github_actions_namespace
spec:
  replicas: 1
  template:
    spec:
      repository: "${REPOSITORY_USERNAME}/${REPOSITORY_NAME}"
      labels:
        - minikube
EOF
# ----------------------------------------------------------------------------------------------------------------- #

