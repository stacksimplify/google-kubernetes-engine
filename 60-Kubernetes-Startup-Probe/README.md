---
title: GCP Google Kubernetes Engine Kubernetes Startup Probes
description: Implement GCP Google Kubernetes Engine Kubernetes Startup Probes
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
- Implement `Startup Probe` and Test it

## Step-02:  Understand Startup Probe 
1. Sometimes, you have to deal with legacy applications that might require an additional startup time on their first initialization. 
2. The application will have a maximum of 5 minutes (30 * 10 = 300s) to  finish its startup. 
3. Once the startup probe has succeeded once, the liveness probe takes over to provide a fast response to container deadlocks. 
4. If the startup probe never succeeds, the container is killed after 300s and subject to the pod's restartPolicy.

## Step-03: Review Startup Probe YAML
- **File Name:** 05-UserMgmtWebApp-Deployment.yaml
```yaml
          # Startup Probe - Wait for 5 minutes till the application starts            
          startupProbe:
            httpGet:
              path: /login
              port: 8080
            initialDelaySeconds: 60              
            periodSeconds: 10            
            failureThreshold: 30  # The application will have a maximum of 5 minutes (30 * 10 = 300s) to finish its startup.
            successThreshold: 1 # Default value                         
```

## Step-04: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests-startup-probe

# List Pods
kubectl get pods
Observation:

# List Services
kubectl get svc

# Access Application
http://<LB-IP>
Username: admin101
Password: password101
```

## Step-05: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests-startup-probe
```