---
title: GCP Google Kubernetes Engine Kubernetes Limit Range
description: Implement GCP Google Kubernetes Engine Kubernetes Limit Range
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
1. Kubernetes Namespaces - LimitRange 
2. Kubernetes Namespaces - Declarative using YAML

## Step-02: Create Namespace manifest
- **Important Note:** File name starts with `01-`  so that when creating k8s objects namespace will get created first so it don't throw an error.
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: qa
```

## Step-03: Create LimitRange manifest
- Instead of specifying `resources like cpu and memory` in every container spec of a pod defintion, we can provide the default CPU & Memory for all containers in a namespace using `LimitRange`
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-cpu-mem-limit-range
  namespace: qa
spec:
  limits:
    - default:
        cpu: "400m"  # If not specified default limit is 1 vCPU per container     
        memory: "256Mi" # If not specified the Container's memory limit is set to 512Mi, which is the default memory limit for the namespace.
      defaultRequest:
        cpu: "200m" # If not specified default it will take from whatever specified in limits.default.cpu      
        memory: "128Mi" # If not specified default it will take from whatever specified in limits.default.memory
      max: 
        cpu: "500m"
        memory: "500Mi"
      min:       
        cpu: "100m"
        memory: "100Mi"
      type: Container  
```


## Step-04: Demo-01: Create Kubernetes Resources & Test
```t
# Create Kubernetes Resources
kubectl apply -f 01-kube-manifests-LimitRange-defaults

# List Pods
kubectl get pods -n qa -w

# View Pod Specification (CPU & Memory)
kubectl describe pod <pod-name> -n qa
Observation: 
1. We will find the "Limits" in pod container equals to "defaults" from LimitRange
2. We will find the "Requests" in pod container equals to "defaultRequest"

# Sample from Pod description
    Limits:
      cpu:     400m
      memory:  256Mi
    Requests:
      cpu:        200m
      memory:     128Mi

# Get & Describe Limits
kubectl get limits -n qa
kubectl describe limits default-cpu-mem-limit-range -n qa

# List Services
kubectl get svc -n qa

# Access Application 
http://<SVC-External-IP>/
```

## Step-05: Demo-01: Clean-Up
- Delete all Kubernetes objects created as part of this section
```t
# Delete All
kubectl delete -f 01-kube-manifests-LimitRange-defaults/
```

## Step-06: Demo-02: Update Demo-02 Deployment Manifest with Requests & Limits
- Negative case testing
- When deployed with these `Requests & Limits`  where `cpu=600m in limits` which is above the `max cpu = 500m` in LimitRange `default-cpu-mem-limit-range` it should not schedule the pods and throw  error in `ReplicaSet Events`. 
- **File Name:** 03-kubernetes-deployment.yaml
```t
# Update Demo-02 Deployment Manifest with Requests & Limits
          resources:
            requests:
              memory: "128Mi" 
              cpu: "450m" 
            limits:
              memory: "256Mi"
              cpu: "600m"  
```

## Step-07: Demo-02: Create Kubernetes Resources & Test
```t
# Create Kubernetes Resources
kubectl apply -f 02-kube-manifests-LimitRange-MinMax

# List Pods
kubectl get pods -n qa
Observation:
1. No Pod should be scheduled

# List Deployments
kubectl get deploy -n qa
Observation: 0/2 ready which means no pods scheduled. Verify ReplicaSet Events

# List & Describe ReplicaSets
kubectl get rs -n qa
kubectl describe rs <ReplicaSet-Name> -n qa
Observation: Below error will be displayed
 Warning  FailedCreate  18s (x5 over 56s)  replicaset-controller  (combined from similar events): Error creating: pods "myapp1-deployment-5dd9f78fd8-k5th6" is forbidden: maximum cpu usage per Container is 500m, but limit is 600m

# Get & Describe Limits
kubectl get limits -n qa
kubectl describe limits default-cpu-mem-limit-range -n qa

# List Services
kubectl get svc -n qa

# Access Application 
http://<SVC-External-IP>/
```

## Step-08: Demo-02: Update Deployment resources.limit=500m
- **File Name:** 03-kubernetes-deployment.yaml
```t
# Demo-02: Update Deployment resources.limit=500m
          resources:
            requests:
              memory: "128Mi" 
              cpu: "450m"
            limits:
              memory: "256Mi"
              cpu: "500m" # This is equal to Max value defined in LimitRange, Pods will be scheduled.   
```

## Step-09: Demo-02: Deploy the updated Deployment
```t
# Deploy the Updated Deployment
kubectl apply -f 02-kube-manifests-LimitRange-MinMax/03-kubernetes-deployment.yaml

# List Pods
kubectl get pods -n qa
Observation:
1. Pods should be scheduled now. 
```

## Step-10: Demo-02: Clean-Up
```t
# Delete Demo-02 Kubernetes Resources
kubectl delete -f 02-kube-manifests-LimitRange-MinMax
```


## References:
- https://kubernetes.io/docs/tasks/administer-cluster/namespaces-walkthrough/
- https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/cpu-default-namespace/
- https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/


