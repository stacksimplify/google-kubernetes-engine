---
title: GCP Google Kubernetes Engine Kubernetes Requests and Limits
description: Implement GCP Google Kubernetes Engine Kubernetes Requests and Limits
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
- We can specify how much each container a pod needs the resources like CPU & Memory. 
- When we provide this information in our pod, the scheduler uses this information to decide which node to place the Pod on. 
- When you specify a resource limit for a Container, the kubelet enforces those `limits` so that the running container is not allowed to use more of that resource than the limit you set. 
-  The kubelet also reserves at least the `request` amount of that system resource specifically for that container to use.

## Step-02: Add Requests & Limits
```yaml
          resources:
            requests:
              memory: "128Mi" # 128 MebiByte is equal to 135 Megabyte (MB)
              cpu: "200m" # `m` means milliCPU
            limits:
              memory: "256Mi"
              cpu: "400m"  # 1000m is equal to 1 VCPU core                                          
```

## Step-03: Create k8s objects & Test
```t
# Create All Objects
kubectl apply -f kube-manifests/

# List Pods
kubectl get pods

# Watch List Pods screen
kubectl get pods -w

# Describe Pod 
kubectl describe pod <myapp1-deployment-xxxxxx>

# Access Application
http://<LB-IP>/

# List Nodes & Describe Node
kubectl get nodes
kubectl describe node <Node-Name>
```
## Step-04: Clean-Up
- No Clean-Up.
- We are going to use this app in next demo which is Cluster Autoscaling

## References:
- https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/