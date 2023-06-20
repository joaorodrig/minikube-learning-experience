Certified Kubernetes Application Developer
******************************************

.. contents:: Table of Contents
    :backlinks: none

Resources
---------

- Certified Kubernetes Application Developer: https://www.cncf.io/certification/ckad/
- Candidate Handbook: https://www.cncf.io/certification/candidate-handbook
- Exam Tips: https://docs.linuxfoundation.org/tc-docs/certification/tips-cka-and-ckad
- Exam Experience: https://medium.com/bb-tutorials-and-thoughts/how-to-pass-the-certified-kubernetes-application-developer-ckad-exam-503e9562d022
- CKAD Pratice Questions: https://github.com/bbachi/CKAD-Practice-Questions/tree/master
- Kubernetes Certified Application Developer (CKAD) with Tests: https://www.udemy.com/course/certified-kubernetes-application-developer/


**Note:** These notes are based on KodeKloud's CKAD Udemy course you can find `here <https://www.udemy.com/course/certified-kubernetes-application-developer/>`_


Minikube Lab Environment
------------------------

Description to follow... (GitHub Actions, ArgoCD, Dev and Prod Environments, etc...) `here <https://github.com/joaorodrig/minikube-learning-experience/tree/main/apps/ckad-lab>`_



Core Concepts
-------------


Container Runtime Interface (CRI) Debug Tools
=============================================

::

    # Use the crictl to troubleshoot container runtime issues
    $ crictl -h
    NAME:
    crictl - client for CRI

    USAGE:
    crictl [global options] command [command options] [arguments...]

    VERSION:
    v1.21.0

    COMMANDS:
    attach              Attach to a running container
    create              Create a new container
    exec                Run a command in a running container
    version             Display runtime version information
    images, image, img  List images
    inspect             Display the status of one or more containers
    inspecti            Return the status of one or more images
    imagefsinfo         Return image filesystem info
    inspectp            Display the status of one or more pods
    logs                Fetch the logs of a container
    port-forward        Forward local port to a pod
    ps                  List containers
    pull                Pull an image from a registry
    run                 Run a new container inside a sandbox
    runp                Run a new pod
    rm                  Remove one or more containers
    rmi                 Remove one or more images
    rmp                 Remove one or more pods
    pods                List pods
    start               Start one or more created containers
    info                Display information of the container runtime
    stop                Stop one or more running containers
    stopp               Stop one or more running pods
    update              Update one or more running containers
    config              Get and set crictl client configuration options
    stats               List container(s) resource usage statistics
    completion          Output shell completion code
    help, h             Shows a list of commands or help for one command

    GLOBAL OPTIONS:
    --config value, -c value            Location of the client config file. If not specified and the default does not exist, the program's directory is searched as well (default: "/etc/crictl.yaml") [$CRI_CONFIG_FILE]
    --debug, -D                         Enable debug mode (default: false)
    --image-endpoint value, -i value    Endpoint of CRI image manager service (default: uses 'runtime-endpoint' setting) [$IMAGE_SERVICE_ENDPOINT]
    --runtime-endpoint value, -r value  Endpoint of CRI container runtime service (default: uses in order the first successful one of [unix:///var/run/dockershim.sock unix:///run/containerd/containerd.sock unix:///run/crio/crio.sock]). Default is now deprecated and the endpoint should be set instead. [$CONTAINER_RUNTIME_ENDPOINT]
    --timeout value, -t value           Timeout of connecting to the server in seconds (e.g. 2s, 20s.). 0 or less is set to default (default: 2s)
    --help, -h                          show help (default: false)
    --version, -v                       print the version (default: false)



Cheatsheets
===========

**kubectl Cheat Sheet:** https://kubernetes.io/docs/reference/kubectl/cheatsheet/

::

    # Create manifest skeletons / imperative commands
    kubectl create namespace test --dry-run=client -o yaml > namespace-definition.yml
    kubectl run nginx --image nginx --dry-run=client -o yaml
    kubectl create deployment --image=nginx nginx --dry-run=client -o yaml
    kubectl create deployment nginx --image=nginx --replicas=4 --dry-run=client -o yaml
    kubectl expose pod redis --port=6379 --name redis-service --dry-run=client -o yaml
    kubectl expose pod nginx --port=80 --name nginx-service --type=NodePort --dry-run=client -o yaml


    # Get manifest from running object
    kubectl get pod nginx -o yaml > pod-definition.yaml

    # Kubectl set namespace in context
    kubectl config set-context $(kubectl config current-context) --namespace NEW_KUBECTL_DEFAULT_NAMESPACE

    # Change output formats
    kubectl [command] [TYPE] [NAME] -o <output_format>

    
Here are some of the commonly used formats:

- -o jsonOutput a JSON formatted API object.
- -o namePrint only the resource name and nothing else.
- -o wideOutput in the plain-text format with any additional information.
- -o yamlOutput a YAML formatted API object.

...

**Default FQDN for Services:** service_name.namespace.svc.cluster.local



Configuration
-------------

Pod Commands and Arguments
==========================

In a Dockerfile, the ENTRYPOINT instruction speficies a 'command prefix' which needs to be completed by the CMD instruction, or CLI argument. When specifying a Kubernetes pod, the ENTRYPOINT and CMD Dockerfile instructions map to the 'command' and 'args' spec attribute, respectively.

::

    # Run Ubuntu pod and sleep for 10 seconds
    apiVersion: v1
    kind: Pod
    metadata:
      name: mypod
      labels:
        type: cmd-example
    spec:
      containers:
        - name: ubuntu-sleeper
          image: ubuntu
          command: ["sleep"]
          args: ["10"]


    # Passing an evironmental variables to the same pod
    apiVersion: v1
    kind: Pod
    metadata:
      name: mypod
      labels:
        type: cmd-example
    spec:
      containers:
        - name: ubuntu-sleeper
          image: ubuntu
          command: ["sleep"]
          args: ["10"]
          env:
            - name: MYVAR1
              value: Value of Var 1



ConfigMaps and Secrets
======================


Creating a ConfigMap using a definition file:

::

    # Definion of the ConfigMap
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: app-config
    data:
      MYVAR1: Value of var1
      MYVAR2: Value of var2



Three ways of injecting it into a container:

::

    # 1. Import all the ConfigMap to the Environment
    envFrom:
      - configMapRef:
          name: CONFIG_MAP_NAME

    # 2. Import specific variables to the Environment
    env:
      - name: MYVAR2
        valueFrom:
          configMapRefKey:
            name: app-config
            key: MYVAR2

    # 3. Mount the ConfigMap as a volume
    volumes:
      - name: app-config-volume
        configMap:
          name: CONFIG_MAP_NAME

