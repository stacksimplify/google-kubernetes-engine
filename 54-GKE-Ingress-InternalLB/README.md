---
title: GCP Google Kubernetes Engine Ingress Internal Load Balancer
description: Implement GCP Google Kubernetes Engine GKE Internal Load Balancer with Ingress
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
- Ingress Internal Load Balancer

## Step-02: Review Kubernetes Deployment manifests
- 01-Nginx-App1-Deployment-and-NodePortService.yaml
- 02-Nginx-App2-Deployment-and-NodePortService.yaml
- 03-Nginx-App3-Deployment-and-NodePortService.yaml

## Step-03: 04-Ingress-internal-lb.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-internal-lb
  annotations:
    # If the class annotation is not specified it defaults to "gce".
    # gce: external load balancer
    # gce-internal: internal load balancer  
    # Internal Load Balancer
    kubernetes.io/ingress.class: "gce-internal"  
spec: 
  defaultBackend:
    service:
      name: app3-nginx-nodeport-service
      port:
        number: 80                            
  rules:
    - http:
        paths:           
          - path: /app1
            pathType: Prefix
            backend:
              service:
                name: app1-nginx-nodeport-service
                port: 
                  number: 80
          - path: /app2
            pathType: Prefix
            backend:
              service:
                name: app2-nginx-nodeport-service
                port: 
                  number: 80                 
```

## Step-04: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f 01-kube-manifests

# List Deployments
kubectl get deploy

# List Pods
kubectl get po

# List Services
kubectl get svc

# List Backend Configs
kubectl get backendconfig

# List Ingress Service
kubectl get ingress

# Describe Ingress Service
kubectl describe ingress ingress-internal-lb

# Verify Load Balancer
Go to Network Services -> Load Balancing -> Load Balancer
```

## Step-05: Review Curl Kubernetes Manifests
- **Project Folder:** 02-kube-manifests-curl
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl-pod
spec:
  containers:
  - name: curl
    image: curlimages/curl 
    command: [ "sleep", "600" ]
```

## Step-06: Deply Curl-pod and Verify Internal LB
```t
# Deploy curl-pod
kubectl apply -f 02-kube-manifests-curl

# Will open up a terminal session into the container
kubectl exec -it curl-pod -- sh

# App1 Curl Test
curl http://<INTERNAL-INGRESS-LB-IP>/app1/index.html

# App2 Curl Test
curl http://<INTERNAL-INGRESS-LB-IP>/app2/index.html

# App3 Curl Test
curl http://<INTERNAL-INGRESS-LB-IP>
```

## Step-07: Clean-Up
```t
# Delete Kubernetes Manifests
kubectl delete -f 01-kube-manifests
kubectl delete -f 02-kube-manifests-curl
```

## References
- [Ingress for Internal HTTP(S) Load Balancing](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress-ilb)