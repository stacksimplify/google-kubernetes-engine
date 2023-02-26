---
title: GCP Google Kubernetes Engine Cluster Autoscaling
description: Implement GKE Cluster Autoscaler concept
---

## Step-00: Pre-requisites
1. Verify if GKE Cluster is created
2. Verify if kubeconfig for kubectl is configured in your local terminal
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>

# Replace Values CLUSTER-NAME, REGION, PROJECT
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123

# List Kubernetes Nodes
kubectl get nodes
```

## Step-01: Introduction
- Test Cluster Autoscaler feature

## Step-02: Verify Cluster Autoscaler enabled for Node Pool
- Go to Kubernetes Engine -> standard-cluster-private-1 -> NODES Tab -> default-pool -> Click on **Edit**
- Check **Enable cluster autoscaler**
- Size limits type
  - Check **Per zone limits**
  - **Minimum number of nodes (per zone):** 0
  - **Maximum number of nodes (per zone):** 3

## Step-03: Verify the 5th Pod from previous Demo is still in Pending State
```t
# List Pods
kubectl get pods

# Describe Pod (PENDING POD)
kubectl describe pod <PENDING-POD-NAME>
Observation:
1. Verify the pod events where we can find the autoscaling event triggered

# List Kubernetes Nodes
kubectl get nodes 
Observation:
1. Nodes in NodePools will be increased from 3 to 4 (2 per zone max we configured)

# Scale-In the demo application to 1 pod
kubectl get pods
kubectl get nodes 
kubectl scale --replicas=1 deploy myapp1-deployment 
kubectl get pods

# List Kubernetes Nodes
kubectl get nodes
1. Nodes in NodePools will be decreased from 4 to 3 (Wait for 10 minutes for Nodes Scale-In)
```

## Step-04: Clean-up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests
```

