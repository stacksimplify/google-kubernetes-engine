---
title: GCP Google Kubernetes Engine - Create GKE Cluster
description: Learn to create Google Kubernetes Engine GKE Cluster
---

## Step-01: Introduction
- Create GKE Standard GKE Cluster 
- Configure Google CloudShell to access GKE Cluster
- Deploy simple Kubernetes Deployment and Kubernetes Load Balancer Service and Test 
- Clean-Up

## Step-02: Create Standard GKE Cluster 
- Go to Kubernetes Engine -> Clusters -> CREATE
- Select **GKE Standard -> CONFIGURE**
- **Cluster Basics**
  - **Name:** standard-public-cluster-1
  - **Location type:** Regional
  - **Region:** us-central1
  - **Specify default node locations:** us-central1-a, us-central1-b, us-central1-c
  - **Release Channel**
    - **Release Channel:** Rapid Channel
    - **Version:** LATEST AVAIALABLE ON THAT DAY
  - REST ALL LEAVE TO DEFAULTS
- **NODE POOLS: default-pool**
- **Node pool details**
  - **Name:** default-pool
  - **Number of Nodes (per zone):** 1
  - **Node Pool Upgrade Strategy:** Surge Upgrade
- **Nodes: Configure node settings** 
  - **Image type:** Containerized Optimized OS
  - **Machine configuration**
    - **GENERAL PURPOSE SERIES:** E2
    - **Machine Type:** e2-small
  - **Boot disk type:** Balanced persistent disk
  - **Boot disk size(GB):** 20
  - **Boot disk encryption:** Google-managed encryption key (default )
  - **Enable Node on Spot VMs:** CHECKED
- **Node Networking:** LEAVE TO DEFAULTS  
- **Node Security:** 
  - **Access scopes:** Allow default access (LEAVE TO DEFAULT)
  - REST ALL REVIEW AND LEAVE TO DEFAULTS
- **Node Metadata:** REVIEW AND LEAVE TO DEFAULTS
- **CLUSTER** 
  - **Automation:** REVIEW AND LEAVE TO DEFAULTS
  - **Networking:** REVIEW AND LEAVE TO DEFAULTS
    - **CHECK THIS BOX: Enable Dataplane V2** CHECK IT - IN FUTURE VERSIONS IT WILL BE BY DEFAULT ENABLED
  - **Security:** REVIEW AND LEAVE TO DEFAULTS
    - **CHECK THIS BOX: Enable Workload Identity** CHECK IT - IN FUTURE VERSIONS IT WILL BE BY DEFAULT ENABLED
  - **Metadata:** REVIEW AND LEAVE TO DEFAULTS
  - **Features:** REVIEW AND LEAVE TO DEFAULTS
- CLICK ON **CREATE**

## Step-03: Verify Cluster Details
- Go to Kubernetes Engine -> Clusters -> **standard-public-cluster-1**
- Review
  - Details Tab
  - Nodes Tab
    - Review same nodes **Compute Engine**
  - Storage Tab
    - Review Storage Classes
  - Logs Tab
    - Review Cluster Logs
    - Review Cluster Logs **Filter By Severity**

## Step-04: Verify Additional Features in GKE on a High-Level
### Step-04-01: Verify Workloads Tab
- Go to Kubernetes Engine -> Clusters -> **standard-public-cluster-1**
- Workloads -> **SHOW SYSTEM WORKLOADS**

### Step-04-02: Verify Services & Ingress
- Go to Kubernetes Engine -> Clusters -> **standard-public-cluster-1**
- Services & Ingress -> **SHOW SYSTEM OBJECTS**

### Step-04-03: Verify Applications, Secrets & ConfigMaps
- Go to Kubernetes Engine -> Clusters -> **standard-public-cluster-1**
- Applications
- Secrets & ConfigMaps

### Step-04-04: Verify Storage
- Go to Kubernetes Engine -> Clusters -> **standard-public-cluster-1**
- Storage Classes
  - premium-rwo
  - standard
  - standard-rwo

### Step-04-05: Verify the below
1. Object Browser
2. Migrate to Containers
3. Backup for GKE
4. Config Management
5. Protect

## Step-05: Google CloudShell: Connect to GKE Cluster using kubectl
- [kubectl Authentication in GKE](https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke)
```t
# Verify gke-gcloud-auth-plugin Installation (if not installed, install it)
gke-gcloud-auth-plugin --version 

# Install Kubectl authentication plugin for GKE
sudo apt-get install google-cloud-sdk-gke-gcloud-auth-plugin

# Verify gke-gcloud-auth-plugin Installation
gke-gcloud-auth-plugin --version 

# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT-NAME>
gcloud container clusters get-credentials standard-public-cluster-1 --region us-central1 --project kdaida123

# Run kubectl with the new plugin prior to the release of v1.25
vi ~/.bashrc
USE_GKE_GCLOUD_AUTH_PLUGIN=True

# Reload the environment value
source ~/.bashrc

# Check if Environment variable loaded in Terminal
echo $USE_GKE_GCLOUD_AUTH_PLUGIN

# Verify kubectl version
kubectl version --short

# Install kubectl (if not installed)
gcloud components install kubectl

# Configure kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --zone <ZONE> --project <PROJECT-ID>
gcloud container clusters get-credentials standard-cluster-1 --zone us-central1-c --project kdaida123

# Verify Kubernetes Worker Nodes
kubectl get nodes

# Verify System Pod in kube-system Namespace
kubectl -n kube-system get pods

# Verify kubeconfig file
cat $HOME/.kube/config
kubectl config view
```

## Step-06: Review Sample Application: 01-kubernetes-deployment.yaml
- **Folder:** kube-manifests
```yaml
apiVersion: apps/v1
kind: Deployment 
metadata: #Dictionary
  name: myapp1-deployment
spec: # Dictionary
  replicas: 2
  selector:
    matchLabels:
      app: myapp1
  template:  
    metadata: # Dictionary
      name: myapp1-pod
      labels: # Dictionary
        app: myapp1  # Key value pairs
    spec:
      containers: # List
        - name: myapp1-container
          image: stacksimplify/kubenginx:1.0.0
          ports: 
            - containerPort: 80  
    
```

## Step-07: Review Sample Application: 02-kubernetes-loadbalancer-service.yaml
- **Folder:** kube-manifests
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: myapp1-lb-service
spec:
  type: LoadBalancer # ClusterIp, # NodePort
  selector:
    app: myapp1
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
```

## Step-08: Upload Sample App to Google CloudShell
```t
# Upload Sample App to Google CloudShell
Go to Google CloudShell -> 3 Dots -> Upload -> Folder -> google-kubernetes-engine

# Change Directory
cd google-kubernetes-engine/02-Create-GKE-Cluster

# Verify folder uploaded
ls kube-manifests/

# Verify Files
cat kube-manifests/01-kubernetes-deployment.yaml
cat kube-manifests/02-kubernetes-loadbalancer-service.yaml
```

## Step-09: Deploy Sample Application and Verify
```t
# Change Directory
cd google-kubernetes-engine/02-Create-GKE-Cluster

# Deploy Sample App using kubectl
kubectl apply -f kube-manifests/

# List Deployments
kubectl get deploy

# List Pods
kubectl get pod

# List Services
kubectl get svc

# Access Sample Application
http://<EXTERNAL-IP>
```

## Step-10: Verify Workloads in GKE Dashboard
- Go to GCP Console -> Kubernetes Engine -> Workloads
- Click on  **myapp1-deployment**
- Review all tabs

## Step-11: Verify Services in GKE Dashboard
- Go to GCP Console -> Kubernetes Engine -> Services & Ingress
- Click on **myapp1-lb-service**
- Review all tabs

## Step-13: Verify Load Balancer
- Go to GCP Console -> Networking Services -> Load Balancing
- Review all tabs

## Step-14: Clean-Up
- Go to Google Cloud Shell
```t
# Change Directory
cd google-kubernetes-engine/02-Create-GKE-Cluster

# Delete Kubernetes Deployment and Service
kubectl delete -f kube-manifests/

# List Deployments
kubectl get deploy

# List Pods
kubectl get pod

# List Services
kubectl get svc
```



