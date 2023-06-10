My Minikube Learning Experience
*******************************

Welcome! This is one of my very first public GitHub repos and contains some learning I'm doing in the Kubernetes space. This is work in progress and it is intended to documen my beginner-to-intermediate learning experience into Kubernetes. I will document in this repository my learning journey towards becoming a Certified Kubernetes Application Developer (CKAD), as well as my learning adventures into the exciting Data Engineering and Analytics world (I'm a traditional Network and Linux guy, who has been doing Cloud Infrastructure and Platform Engineering for the last 5 years).

This environment is built on my personal Ubuntu 22.04 machine, using Linux KVM, Minikube, Hashicorp Vagrant, GitHub Actions for CI/CD, as well as ArgoCD. I hope you enjoy this, and feel free to get in touch. Please note this is work-in-progress I do in my free time, after looking after my family and I.


.. contents:: Table of Contents
    :backlinks: none


Environment Setup
-----------------

- To install see `here <setup.rst>`_
- To start environment:

  ::

    # Start NFS Host to store the Persistent Volumes
    $ vagrant up

    # Start minikube
    $ minikube start

    # Verify both machines are up
    $ virsh list --all
    Id   Name                     State
    ----------------------------------------
    1    vagrant_minikube-nfs-1   running
    2    minikube                 running


    # Get default ArgoCD password (user is admin)
    $ argocd admin initial-password -n argocd | head -1

    # Enable kubectl port forwarding to ArgoCD UI
    $ kubectl port-forward svc/argocd-server -n argocd 8080:443 &>/dev/null &


- If running for the first time, trigger the ArgoCD configuration pipeline by clickin in 'Run workflow' (screenshot below)

  .. figure:: docs/pics/trigger-argocd-test-pipeline.png
     :scale: 100%


- Login to the ArgoCD UI (https://127.0.0.1:8080) with 'admin' and the default password (if you didn't change it), and verify that the hello-world application is deployed into minikube (screenshot below). This is configured from the following manifest: 'argocd-manifests/argocd-hello-world.yml',

  .. figure:: docs/pics/trigger-argocd-hello-world.png
     :scale: 100%


Project Index
-------------

- **CKAD:** `here <docs/ckad.rst>`_
- **Monitoring:** `here <docs/monitoring.rst>`_
- **Object Storage:** `here <docs/ceph.rst>`_
- **Relational Database:** `here <docs/postgres.rst>`_
- **NoSQL / Document Database:** `here <docs/mongodb.rst>`_
- **Data Pipelines:** `here <docs/pyspark.rst>`_
- **Data Pipeline Orchestration**: `here <docs/airflow.rst>`_


