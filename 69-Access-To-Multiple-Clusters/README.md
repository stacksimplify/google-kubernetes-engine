---
title: GCP Google Kubernetes Engine Access to Multiple Clusters
description: Implement GCP Google Kubernetes Engine Access to Multiple Clusters
---

## Step-00: Pre-requisites
- We should have the two clusters created and ready
- standard-cluster-private-1
- autopilot-cluster-private-1

## Step-01: Introduction
- Configure access to Multiple Clusters
- Understand kube config file $HOME/.kube/config
- Understand kubectl config command
  - kubectl config view
  - kubectl config current-context
  - kubectl config use-context <context-name>
  - kubectl config get-context
  - kubectl config get-clusters


## Step-02: Pre-requisite
- Verify if you have any two GKE Clusters created and ready for use
- standard-cluster-private-1
- autopilot-cluster-private-1

## Step-03: Clean-Up kube config file
```t
# Clean existing kube configs
cd $HOME/.kube
>config
cat config
```

## Step-04: Configure Standard Cluster Access for kubectl
- Understand commands 
  - kubectl config view
  - kubectl config current-context
```t
# View kubeconfig
kubectl config view

# Configure kubeconfig for kubectl: standard-cluster-private-1 
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123

# View kubeconfig
kubectl config view

# View Cluster Information
kubectl cluster-info

# View the current context for kubectl
kubectl config current-context
```

## Step-05: Configure Autopilot Cluster Access for kubectl
```t
# Configure kubeconfig for kubectl: autopilot-cluster-private-1
gcloud container clusters get-credentials autopilot-cluster-private-1 --region us-central1 --project kdaida123

# View the current context for kubectl
kubectl config current-context

# View Cluster Information
kubectl cluster-info

# View kubeconfig
kubectl config view
```

## Step-06: Switch Contexts between clusters
- Understand the kubectl config command **use-context**
```t
# View the current context for kubectl
kubectl config current-context

# View kubeconfig
kubectl config view 
Get contexts.context.name to which you want to switch 

# Switch Context
kubectl config use-context gke_kdaida123_us-central1_standard-cluster-private-1

# View the current context for kubectl
kubectl config current-context

# View Cluster Information
kubectl cluster-info
```

## Step-07: List Contexts configured in kubeconfig
```t
# List Contexts
kubectl config get-contexts
```

## Step-08: List Clusters configured in kubeconfig
```t
# List Clusters
kubectl config get-clusters
```