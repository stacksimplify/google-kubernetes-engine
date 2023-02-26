---
title: GCP Google Kubernetes Engine Kubernetes Readiness Probes
description: Implement GCP Google Kubernetes Engine Kubernetes Readiness Probes
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
- Implement `Readiness Probe` and Test it

## Step-02:  Understand Readiness Probe 
1. Sometimes, applications are temporarily unable to serve traffic. 
2. For example, an application might need to load large data or configuration files during startup, or depend on external services after startup. 
3. In such cases, you don't want to kill the application, but you don't want to send it requests either. 
4. Kubernetes provides readiness probes to detect and mitigate these situations. 
5. A pod with containers reporting that they are not ready does not receive traffic through Kubernetes Services.
6. Readiness probes runs on the container during its whole lifecycle.
7. Liveness probes do not wait for readiness probes to succeed. 
8. If you want to wait before executing a liveness probe you should use initialDelaySeconds or a startupProbe.
9. Readiness and liveness probes can be used in parallel for the same container. 
10. Using both can ensure that traffic does not reach a container that is not ready for it, and that containers are restarted when they fail.

## Step-03: Review Readiness Probe YAML
- **File Name:** 05-UserMgmtWebApp-Deployment.yaml
```yaml
          # Readiness Probe HTTP Request            
          readinessProbe:
            httpGet:
              path: /login
              port: 8080
              httpHeaders:
              - name: Custom-Header
                value: Awesome   
            initialDelaySeconds: 60
            periodSeconds: 10
            failureThreshold: 3 # Default Value
            successThreshold: 1 # Default value            
```

## Step-04: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests-readiness-probe

# List Pods
kubectl get pods
Observation:
1. You can see that Pod is running but it will not be ready for 60 seconds. 
2. "initialDelaySeconds=60" is defined in readiness probe so it will mark
the pod as ready only after 60 seconds
3. Liveness probe will start working after "initialDelaySeconds: 120"
4. This way first Readiness probe will run later liveness probe will run. 

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
kubectl delete -f kube-manifests-readiness-probe
```