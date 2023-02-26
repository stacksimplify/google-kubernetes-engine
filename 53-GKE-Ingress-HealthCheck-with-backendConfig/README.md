---
title: GCP Google Kubernetes Engine GKE Ingress Custom Health Checks
description: Implement GCP Google Kubernetes Engine GKE Ingress Custom Health Checks
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
- Implement Ingress Custom Health Checks
- Comment `Readiness Probe` in Kubernetes Deployment.
- Add Custom Health Checks in `kind: BackendConfig` Kubernetes Resource

## Step-02: 01-kubernetes-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app3-nginx-deployment
  labels:
    app: app3-nginx 
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app3-nginx
  template:
    metadata:
      labels:
        app: app3-nginx
    spec:
      containers:
        - name: app3-nginx
          image: stacksimplify/kubenginx:1.0.0
          ports:
            - containerPort: 80
          # Readiness Probe (https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#def_inf_hc)            
          #readinessProbe:
          #  httpGet:
          #    scheme: HTTP
          #    path: /index.html
          #    port: 80
          #  initialDelaySeconds: 10
          #  periodSeconds: 15
          #  timeoutSeconds: 5    
```

## Step-03: 02-kubernetes-NodePort-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app3-nginx-nodeport-service
  labels:
    app: app3-nginx
  annotations:
    #cloud.google.com/backend-config: '{"ports": {"80":"my-backendconfig"}}' 
    cloud.google.com/backend-config: '{"default": "my-backendconfig"}'     
spec:
  type: NodePort
  selector:
    app: app3-nginx
  ports:
    - port: 80
      targetPort: 80
```

## Step-04: 03-ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-custom-healthcheck
  annotations:
    # External Load Balancer
    kubernetes.io/ingress.class: "gce"  
spec:          
  defaultBackend:
    service:
      name: app3-nginx-nodeport-service
      port:
        number: 80     
```
## Step-05: 04-backendconfig.yaml
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
  healthCheck:
    checkIntervalSec: 5 # Default is 5 seconds
    timeoutSec: 5 # The value of timeoutSec must be less than or equal to the checkIntervalSec
    healthyThreshold: 2 # Default value 2
    unhealthyThreshold: 2 # Default value 2
    type: HTTP # The BackendConfig only supports creating health checks using the HTTP, HTTPS, or HTTP2 protocols
    requestPath: /index.html
    port: 80
```
## Step-06: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests

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
```

## Step-07: Verify Load Balancer Details
- Go to Network Services -> Loadbalancing -> Load Balancer
- Backends -> Backend -> Click on **Health check related link**
- Verify health check details

## Step-08: Access Application
```t
# List Ingress Service
kubectl get ingress

# Access Application
http://<ADDRESS-FROM-GET-INGRESS-OUTPUT>
```
## Step-09: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests
```

## References
- [Ingress Health Checks](https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#health_checks)
- [Custom Health Check Configuration](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#direct_health)