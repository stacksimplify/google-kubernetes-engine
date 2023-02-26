---
title: GCP Google Kubernetes Engine Horizontal Pod Autoscaling
description: Implement GKE Cluster Horizontal Pod Autoscaling
---

## Step-00: Pre-requisites
1. Verify if GKE Cluster is created
2. Verify if kubeconfig for kubectl is configured in your local terminal
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>

# Replace Values CLUSTER-NAME, REGION, PROJECT
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123
```

## Step-01: Introduction
- Implement a Sample Demo with Horizontal Pod Autoscaler

## Step-02: Review Kubernetes Manifests
- Primarily review `HorizontalPodAutoscaler` Resource in file `03-kubernetes-hpa.yaml`
1. 01-kubernetes-deployment.yaml
2. 02-kubernetes-cip-service.yaml
3. 03-kubernetes-hpa.yaml
```yaml
apiVersion: autoscaling/v1
kind: HorizontalPodAutoscaler
metadata:
 name: hpa-myapp1
spec:
 scaleTargetRef:
   apiVersion: apps/v1
   kind: Deployment
   name: myapp1-deployment
 minReplicas: 1
 maxReplicas: 10
 targetCPUUtilizationPercentage: 50
```

## Step-03: Deploy Sample App and Verify using kubectl
```t
# Deploy Sample
kubectl apply -f kube-manifests

# List Pods
kubectl get pods
Observation: 
1. Currently only 1 pod is running

# List HPA
kubectl get hpa


# Run Load Test (New Terminal)
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh -c "while sleep 0.01; do wget -q -O- http://myapp1-cip-service; done"


# List Pods (SCALE UP EVENT)
kubectl get pods
Observation:
1. New pods will be created to reduce the CPU spikes

# List HPA (after few mins - approx 10 mins)
kubectl get hpa

# List Pods (SCALE IN EVENT)
kubectl get pods
Observation:
1. Only 1 pod should be running
```


## Step-04: Clean-Up
```t
# Delete Load Generator Pod which is in Error State
kubectl delete pod load-generator

# Delete Sample App
kubectl delete -f kube-manifests
```


