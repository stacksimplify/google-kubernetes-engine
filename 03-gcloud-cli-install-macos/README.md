---
title: gcloud cli install on macOS
description: Learn to install gcloud cli on MacOS
---

## Step-01: Introduction
- Install gcloud CLI on MacOS
- Configure kubeconfig for kubectl on your local terminal
- Verify if you are able to reach GKE Cluster using kubectl from your local terminal

## Step-02: Install gcloud cli on MacOS
- [Install gcloud cli](https://cloud.google.com/sdk/docs/install-sdk#mac)
```t
# Verify Python Version (Supported versions are Python 3 (3.5 to 3.8, 3.7 recommended)
python3 -V

# Determine your machine hardware 
uname -m

# Create Folder
mkdir gcloud-cli-software

# Download gcloud cli based on machine hardware 
## Important Note: Download the latest version available on that respective day
Dowload Link: https://cloud.google.com/sdk/docs/install-sdk#mac

## As on today the below is the latest version (x86_64 bit)
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-418.0.0-darwin-x86_64.tar.gz

# Unzip binary
ls -lrta
tar -zxf google-cloud-cli-418.0.0-darwin-x86_64.tar.gz

# Run the install script with screen reader mode on:
./google-cloud-sdk/install.sh --screen-reader=true
```

## Step-03: Verify gcloud cli version
```t
# Open new terminal
AS PATH is updated, open new terminal

# gcloud cli version
gcloud version

## Sample Output
Kalyans-Mac-mini:gcloud-cli-software kalyanreddy$ gcloud version
Google Cloud SDK 418.0.0
bq 2.0.85
core 2023.02.13
gcloud-crc32c 1.0.0
gsutil 5.20
Kalyans-Mac-mini:gcloud-cli-software kalyanreddy$
```

## Step-04: Intialize gcloud CLI in local Terminal 
```t
# Initialize gcloud CLI
./google-cloud-sdk/bin/gcloud init

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
# Change Directroy
gcloud-cli-software

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
kubectl version --short
which kubectl 
Observation: 
1. We are not using kubectl from gcloud CLI and we need to fix that. 

# Removing existing kubectl
which kubectl
rm /usr/local/bin/kubectl
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
OPEN NEW TERMINAL AS PATH IS UPDATED
kubectl version --short
which kubectl
```


## Step-08: Fix kubectl client version equal to GKE Cluster version
- **Important Note:** You must use a kubectl version that is within one minor version difference of your Kubernetescluster control plane. 
- For example, a 1.24 kubectl client works with Kubernetes Cluster 1.23, 1.24 and 1.25 clusters.
- As our GKE cluster version is 1.26, we will also upgrade our kubectl to 1.26
```t
# Verify kubectl version
OPEN NEW TERMINAL AS PATH IS UPDATED
kubectl version --short
which kubectl

# Change Directroy 
cd /Users/kalyanreddy/Documents/course-repos/gcloud-cli-software/google-cloud-sdk/bin/

# List files
ls -lrta

# Backup existing kubectl
cp kubectl kubectl_bkup_1.24

# Copy latest kubectl
cp kubectl.1.26 kubectl

# Verify kubectl version
kubectl version --short
which kubectl
```

## Step-09: Configure kubeconfig for kubectl in local desktop terminal
```t
# Clean-Up kubeconfig file (if any older configs exists)
rm $HOME/.kube/config

# Configure kubeconfig for kubectl 
gcloud container clusters get-credentials <GKE-CLUSTER-NAME> --region <REGION> --project <PROJECT>
gcloud container clusters get-credentials standard-public-cluster-1 --region us-central1 --project kdaida123

# Verify Kubernetes Worker Nodes
kubectl get nodes


# Verify System Pod in kube-system Namespace
kubectl -n kube-system get pods

# Verify kubeconfig file
cat $HOME/.kube/config
kubectl config view
```



## References
- [gcloud CLI](https://cloud.google.com/sdk/gcloud)
- [Install the Google Cloud CLI](https://cloud.google.com/sdk/docs/install-sdk#mac)