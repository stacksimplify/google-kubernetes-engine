---
title: GCP Google Kubernetes Engine Kubernetes Namespaces Imperative
description: Implement GCP Google Kubernetes Engine Kubernetes Namespaces Imperative
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
- Namespaces allow to split-up resources into different groups.
- Resource names should be unique in a namespace
- We can use namespaces to create multiple environments like dev, staging and production etc
- Kubernetes will always list the resources from `default namespace` unless we provide exclusively from which namespace we need information from.

## Step-02: Namespaces Imperative - Create dev Namespace
### Step-02-01: Create Namespace
```t
# List Namespaces
kubectl get ns 

# Craete Namespace
kubectl create namespace <namespace-name>
kubectl create namespace dev

# List Namespaces
kubectl get ns 
```
### Step-02-02: Deploy All k8s Objects
```t
# Deploy All k8s Objects
kubectl apply -f 01-kube-manifests-imperative/ -n dev

# List Namespaces
kubectl get ns

# List Deployments from dev Namespace
kubectl get deploy -n dev

# List Pods from dev Namespace
kubectl get pods -n dev

# List Services from dev Namespace
kubectl get svc -n dev

# List all objects from dev Namespaces
kubectl get all -n dev

# Access Application
http://<LB-Service-External-IP>/
```

## Step-03: Namespace Declarative - Create qa Namespace

### Step-03-01: Namespace Kubernetes YAML Manifest
- **File Name:** 00-kubernetes-namespace.yaml
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: qa
```

### Step-03-02: Update Namespace in Deployment and Service YAML Manifest
- We are going to update the `namespace: qa` in `metadata` section of Deployment and Service
```yaml
# Deployment YAML Manifest
apiVersion: apps/v1
kind: Deployment 
metadata: 
  name: myapp1-deployment
  namespace: qa
spec: 

# Service YAML Manifest
apiVersion: v1
kind: Service 
metadata:
  name: myapp1-lb-service
  namespace: qa
spec:
```

### Step-03-03: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f 02-kube-manifests-declarative

# List Namespaces
kubectl get ns

# List Deployments from qa Namespace
kubectl get deploy -n qa

# List Pods from qa Namespace
kubectl get pods -n qa

# List Services from qa Namespace
kubectl get svc -n qa

# List all objects from qa Namespaces
kubectl get all -n qa

# Access Application
http://<LB-Service-External-IP>/
```

## Step-04: Clean-Up Resources
- If we delete Namespace, all resources associated with namespace will get deleted.
```t
# Delete dev Namespace
kubectl delete ns dev

# List Namespaces
kubectl get ns
Observation:
1. dev namespace should  not be present

# Verify Pods from dev Namespace
kubectl get pods -n dev
Observation: We should not find any pods because namespace itself doesnt exists

# Delete qa Namespace Resources (only)
kubectl delete -f 02-kube-manifests-declarative

# List Namespaces
kubectl get ns

# Delete qa Namespace
kubectl delete ns qa

# List Namespaces
kubectl get ns
```

## References:
- https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/