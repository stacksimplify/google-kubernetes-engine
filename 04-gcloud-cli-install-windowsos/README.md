---
title: gcloud cli install on macOS
description: Learn to install gcloud cli on WindowsOS
---

## Step-01: Introduction
- Install gcloud CLI on WindowsOS
- Configure kubeconfig for kubectl on your local terminal
- Verify if you are able to reach GKE Cluster using kubectl from your local terminal
- Fix kubectl version to match with GKE Cluster Server Version. 

## Step-02: Install gcloud cli on WindowsOS
- [Install gcloud cli on WindowsOS](https://cloud.google.com/sdk/docs/install-sdk#windows)
```t
## Important Note: Download the latest version available on that respective day
Dowload Link: https://cloud.google.com/sdk/docs/install-sdk#windows

## Run the Installer
GoogleCloudSDKInstaller.exe
```

## Step-03: Verify gcloud cli version
```t
# gcloud cli version
gcloud version
```

## Step-04: Intialize gcloud CLI in local Terminal 
```t
# Initialize gcloud CLI
gcloud init

# List accounts whose credentials are stored on the local system:
gcloud auth list

# List the properties in your active gcloud CLI configuration
gcloud config list

# View information about your gcloud CLI installation and the active configuration
gcloud info

# gcloud config Configurations Commands (For Reference)
gcloud config list
gcloud config configurations list
gcloud config configurations activate
gcloud config configurations create
gcloud config configurations delete
gcloud config configurations describe
gcloud config configurations rename
```

## Step-05: Verify gke-gcloud-auth-plugin 
```t
## Important Note about gke-gcloud-auth-plugin: 
1. Kubernetes clients require an authentication plugin, gke- gcloud-auth-plugin, which uses the Client-go Credential Plugins framework to provide authentication tokens to communicate with GKE clusters

# Verify if gke-gcloud-auth-plugin installed
gke-gcloud-auth-plugin --version

# Install gke-gcloud-auth-plugin
gcloud components install gke-gcloud-auth-plugin

# Verify if gke-gcloud-auth-plugin installed
gke-gcloud-auth-plugin --version
```

## Step-06: Remove any existing kubectl clients
```t
# Verify kubectl version
kubectl version --output=yaml
Observation: 
1. If any kubectl exists before installing it from gcloud then uninstall it.
2. Usually if docker is installed on our desktop, its equivalent kubectl package mostly will be installed and set on PATH. If exists please remove it.  

```

## Step-07: Install kubectl client from gcloud CLI
```t
# List gcloud components
gcloud components list

## SAMPLE OUTPUT
Status: Not Installed
Name: kubectl
ID: kubectl
Size: < 1 MiB

# Install kubectl client
gcloud components install kubectl

# Verify kubectl version
kubectl version --output=yaml
```


## Step-08: Configure kubeconfig for kubectl in local desktop terminal
```t
# Verify kubeconfig file
kubectl config view

# Configure kubeconfig for kubectl 
gcloud container clusters get-credentials <GKE-CLUSTER-NAME> --region <REGION> --project <PROJECT>
gcloud container clusters get-credentials standard-public-cluster-1 --region us-central1 --project kdaida123

# Verify kubeconfig file
kubectl config view

# Verify Kubernetes Worker Nodes
kubectl get nodes
Observation: 
1. It should throw warning at the end about huge difference in kubectl client version and GKE Cluster Server Version
2. Lets fix that in next step. 

```
## Step-09: Fix kubectl client version equal to GKE Cluster version
- **Important Note:** You must use a kubectl version that is within one minor version difference of your Kubernetescluster control plane. 
- For example, a 1.24 kubectl client works with Kubernetes Cluster 1.23, 1.24 and 1.25 clusters.
- As our GKE cluster version is 1.26, we will also upgrade our kubectl to 1.26
```t
# Verify kubectl version
kubectl version --output=yaml

# Change Directroy 
Go to Google Cloud SDK "bin" directory

# Backup existing kubectl
Backup "kubectl" to "kubectl_bkup_1.24"

# Copy latest kubectl
COPY  "kubectl.1.26" as "kubectl"

# Verify kubectl version
kubectl version --output=yaml
```

## References
- [gcloud CLI](https://cloud.google.com/sdk/gcloud)
- [Install the Google Cloud CLI](https://cloud.google.com/sdk/docs/install-sdk#mac)