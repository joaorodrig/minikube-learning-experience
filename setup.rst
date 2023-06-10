Setting up Minikube, GitHub Actions, ArgoCD
*******************************************

.. contents:: Table of Contents
    :backlinks: none


Pre-requisites
--------------
  
- Assuming the use of a private GitHub repository, generate a new private token with read permissions `here <https://github.com/settings/tokens>`_
  
  - Legacy Token -> $REPOSITORY_REPO_TOKEN
  - PAT Token -> $REPOSITORY_PAT_TOKEN

- Vagrant is installed with KVM support
- Storage Pool 'vagrantpool' exists, or alternatively change your KVM storage pool name in the vagrant file
- Make sure that the 'default' network exists in the KVM host (shared betweek the minikube and the vagrant instances)



GitHub Token Configuration
--------------------------

Tbc...



Run Scripts
-----------

1. Setup minikube with GitHub Actions runner and ArgoCD

::

    # Paste your repository variables
    export REPOSITORY_USERNAME="joaorodrig"
    export REPOSITORY_NAME="minikube-learning-experience"
    export REPOSITORY_URL="https://github.com/${REPOSITORY_USERNAME}/${REPOSITORY_NAME}"
    export REPOSITORY_PAT_TOKEN="<INSERT_PAT_TOKEN_PRIVATE_REPO>"
    export REPOSITORY_REPO_TOKEN="<INSERT_LEGACY_TOKEN_PRIVATE_REPO>"
    
    # Install minikube, runners, etc
    scripts/install-minikube-kvm.sh

    # Install ArgoCD
    scripts/install-argo-cd.sh

    # Enable port forwarding to the ArgoCD UI
    kubectl port-forward svc/argocd-server -n argocd 8080:443 &>/dev/null &

    # Get the default ArgoCD UI for the admin user
    argo_initial_password=$(argocd admin initial-password -n argocd | head -1)
    
    # Verify correct operation
    kubectl -n default get all
    kubectl -n github-actions-runner get all
    kubectl -n argocd get all


2. Setup secrets variables in GitHub Actions to access minikube cluster:
  
- In your repository in GitHub, go to Settings -> Security -> Actions -> New Repository Secret
- Get the Kubeconfig from your machine in base64 encoding

::
      
  # Read the minikube certs and key into variables
  export MINIKUBE_CA=$(cat ~/.minikube/ca.crt | base64 -w 0)
  export MINIKUBE_CERT=$(cat ~/.minikube/profiles/minikube/client.crt | base64 -w 0)
  export MINIKUBE_KEY=$(cat ~/.minikube/profiles/minikube/client.key | base64 -w 0)

  # Genere the kubeconfig with cert and key material
  MINIKUBE_CONF_BASE64=$(cat ~/.kube/config \
    | sed "s/client-certificate:.*/client-certificate-data: \$MINIKUBE_CERT/g" \
    | sed "s/client-key:.*/client-key-data: \$MINIKUBE_KEY/g" \
    | sed "s/certificate-authority:.*/certificate-authority-data: \$MINIKUBE_CA/g" \
    | envsubst | base64 -w 0)


- Use the following content:
  - Name: MINIKUBE_CONFIG
  - Secret: <copy the content of the command executed in your host: $MINIKUBE_CONF_BASE64>



Resources
---------

- **GitHub Actions Manual:** `here <https://docs.github.com/en/actions/quickstart>`_
- **ArgoCD Getting Started Guide:** `here <https://argo-cd.readthedocs.io/en/stable/getting_started/>`_
- **ArgoCD Application Examples:** `here <https://github.com/argoproj/argocd-example-apps>`_
- **ArgoCD Declarative Setup:** `here <https://argo-cd.readthedocs.io/en/stable/operator-manual/declarative-setup/>`_