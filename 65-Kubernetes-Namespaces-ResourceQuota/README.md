---
title: GCP Google Kubernetes Engine Kubernetes Resource Quota
description: Implement GCP Google Kubernetes Engine Kubernetes Resource Quota
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
# Step-01: Introduction
1. Kubernetes Namespaces - ResourceQuota 
2. Kubernetes Namespaces - Declarative using YAML

## Step-02: Create Namespace manifest
- **Important Note:** File name starts with `01-`  so that when creating k8s objects namespace will get created first so it don't throw an error.
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: qa
```

## Step-03: Create Kubernetes ResourceQuota manifest
- **File Name:** 02-kubernetes-resourcequota.yaml
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: ns-resource-quota
  namespace: qa
spec:
  hard:
    requests.cpu: "1"
    requests.memory: 1Gi
    limits.cpu: "2"
    limits.memory: 2Gi  
    pods: "3"    
    configmaps: "3" 
    persistentvolumeclaims: "3" 
    secrets: "3" 
    services: "3"                   
```

## Step-04: Create Kubernetes objects & Test
```t
# Create All Objects
kubectl apply -f kube-manifests/

# List Pods
kubectl get pods -n qa -w

# View Pod Specification (CPU & Memory)
kubectl describe pod <pod-name> -n qa

# Get Resource Quota  - default Namespace
kubectl get resourcequota
kubectl describe resourcequota gke-resource-quotas
Observation:
1. gke-resource-quotas will be precreated by GKE Cluster for each namespace. 
2. Any new quotas we define below the GKE Resource quota limits, that quota will be overrided by default GKE Resource Quota in a Namespace.   


# Get Resource Quota - qa Namespace
kubectl get resourcequota -n qa

# Describe Resource Quota - qa Namespace
kubectl describe resourcequota qa-namespace-resource-quota -n qa

# Test Quota by increasing the pods to 4 where in resource quota is 3 pods only
kubectl get deploy -n qa
kubectl get pods -n qa
kubectl scale --replicas=4 deployment/myapp1-deployment -n qa
kubectl get pods -n qa
kubectl get deploy -n qa

# Verify Deployment and ReplicaSet Events
kubectl describe deploy <Deployment-Name> -n qa
kubectl describe rs <ReplicaSet-Name> -n qa
Observation: In ReplicaSet Events we should find the error

## WARNING MESSAGE IN REPLICASET EVENTS ABOUT RESOURCE QUOTA
Warning  FailedCreate      77s                replicaset-controller  Error creating: pods "myapp1-deployment-5b4bdfc49d-92t9z" is forbidden: exceeded quota: qa-namespace-resource-quota, requested: pods=1, used: pods=3, limited: pods=3

# List Services
kubectl get svc -n qa

# Access Application
http://<SVC-EXTERNAL-IP>
```
## Step-05: Clean-Up
- Delete all Kubernetes objects created as part of this section
```t
# Delete All
kubectl delete -f kube-manifests/ -n qa

# List Namespaces
kubectl get ns
```

## References:
- https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/
- https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/quota-memory-cpu-namespace/


## Additional References:
- https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/cpu-constraint-namespace/ 
- https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-constraint-namespace/
