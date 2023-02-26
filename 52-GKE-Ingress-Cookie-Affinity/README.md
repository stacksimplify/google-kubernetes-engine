---
title: GCP Google Kubernetes Engine GKE Ingress Cookie Affinity
description: Implement GCP Google Kubernetes Engine GKE Ingress Cookie Affinity
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
3. ExternalDNS Controller should be installed and ready to use
```t
# List Namespaces (external-dns-ns namespace should be present)
kubectl get ns

# List External DNS Pods
kubectl -n external-dns-ns get pods
```

## Step-01: Introduction
- Implement following Features for Ingress Service
- BackendConfig - GENERATED_COOKIE Affinity for Ingress Service
- We are going to create two projects
  - **Project-01:** GENERATED_COOKIE Affinity enabled
  - **Project-02:** GENERATED_COOKIE Affinity disabled

## Step-02: Create External IP Address using gcloud
```t
# Create External IP Address 1 (IF NOT CREATED - ALREADY CREATED IN PREVIOUS SECTIONS)
gcloud compute addresses create ADDRESS_NAME --global
gcloud compute addresses create gke-ingress-extip1 --global

# Create External IP Address 2
gcloud compute addresses create ADDRESS_NAME --global
gcloud compute addresses create gke-ingress-extip2 --global

# Describe External IP Address to get
gcloud compute addresses describe ADDRESS_NAME --global
gcloud compute addresses describe gke-ingress-extip2 --global

# Verify
Go to VPC Network -> IP Addresses -> External IP Address
```

## Step-03: Project-01: Review YAML Manifests
- **Project Folder:** 01-kube-manifests-with-cookie-affinity 
- 01-kubernetes-deployment.yaml
- 02-kubernetes-NodePort-service.yaml
- 03-ingress.yaml
- 04-backendconfig.yaml
```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: my-backendconfig
spec:
  timeoutSec: 42 # Backend service timeout: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#timeout
  connectionDraining: # Connection draining timeout: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#draining_timeout
    drainingTimeoutSec: 62
  logging: # HTTP access logging: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#http_logging
    enable: true
    sampleRate: 1.0
  sessionAffinity:
    affinityType: "GENERATED_COOKIE"
```

## Step-04: Project-02: Review YAML Manifests
- **Project Folder:** 02-kube-manifests-without-cookie-affinity
- 01-kubernetes-deployment.yaml
- 02-kubernetes-NodePort-service.yaml
- 03-ingress.yaml
- 04-backendconfig.yaml
```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: my-backendconfig2
spec:
  timeoutSec: 42 # Backend service timeout: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#timeout
  connectionDraining: # Connection draining timeout: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#draining_timeout
    drainingTimeoutSec: 62
  logging: # HTTP access logging: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#http_logging
    enable: true
    sampleRate: 1.0
```
## Step-05: Deploy Kubernetes Manifests
```t
# Project-01: Deploy Kubernetes Manifests 
kubectl apply -f 01-kube-manifests-with-cookie-affinity

# Project-02: Deploy Kubernetes Manifests 
kubectl apply -f 02-kube-manifests-without-cookie-affinity

# Verify Deployments
kubectl get deploy 

# Verify Pods
kubectl get pods

# Verify Node Port Services
kubectl get svc

# Verify Ingress Services
kubectl get ingress

# Verify Backend Config
kubectl get backendconfig

# Project-01: Verify Load Balancer Settings
Go to Network Services -> Load Balancing -> Load Balancer -> Backends -> Verify Cookie Affinity Setting
Observation:
Cookie Affinity setting should be in enabled state

# Project-02: Verify Load Balancer Settings
Go to Network Services -> Load Balancing -> Load Balancer -> Backends -> Verify Cookie Affinity Setting
Cookie Affinity setting should be in disabled state
```

## Step-06: Access Application
```t
# Project-01: Access Application using DNS or ExtIP
http://ingress-with-cookie-affinity.kalyanreddydaida.com
http://<EXT-IP-1>
Observation:
1. Request will keep going always to only one POD due to GENERATED_COOKIE Affinity we configured

# Project-02: Access Application using DNS or ExtIP
http://ingress-without-cookie-affinity.kalyanreddydaida.com
http://<EXT-IP-2>
Observation:
1. Requests will be load balanced to 4 pods created as part of "cdn-demo2" deployment.
```
## Step-07: Clean-Up
```t
# Project-01: Delete Kubernetes Resources 
kubectl delete -f 01-kube-manifests-with-cookie-affinity

# Project-02: Delete Kubernetes Resources 
kubectl delete -f 02-kube-manifests-without-cookie-affinity
```

## References
- [Ingress Features](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features)



http://ingress-without-cookie-affinity.kalyanreddydaida.com
http://ingress-with-cookie-affinity.kalyanreddydaida.com