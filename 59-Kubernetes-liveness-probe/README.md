---
title: GCP Google Kubernetes Engine Kubernetes Liveness Probes
description: Implement GCP Google Kubernetes Engine Kubernetes Liveness Probes
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
- Implement `Liveness Probe` and Test it

## Step-02:  Understand Liveness Probe 
1. Liveness probes lets Kubernetes know whether our application running in a container inside a pod is healthy or not.
2. If our application is healthy Kubernetes will not involve with the pod functioning. If our application is unhealthy Kubernetes will mark the pod as unhealthy.
3. If our application is healthy Kubernetes will not involve with the pod functioning. If our application is unhealthy Kubernetes will mark the pod as unhealthy.
4. In short, Use liveness probe to remove unhealthy pods

## Step-03: Liveness Probe Type: Command
### Step-03-01: Review Liveness Probe Type: Command
- **File Name:** `01-liveness-probe-linux-command/05-UserMgmtWebApp-Deployment.yaml`
```yaml
          # Liveness Probe Linux Command                   
          livenessProbe:
            exec:
              command: 
                - /bin/sh
                - -c 
                - nc -z localhost 8080
            initialDelaySeconds: 60 # initialDelaySeconds field tells  the kubelet that it should wait 60 seconds before performing the first probe. 
            periodSeconds: 10 # periodSeconds field specifies kubelet should perform a liveness probe every 10 seconds. 
            failureThreshold: 3 # Default Value
            successThreshold: 1 # Default value                      
```

### Step-03-02: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f 01-liveness-probe-linux-command

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

### Step-03-03: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f 01-liveness-probe-linux-command
```


## Step-04: Liveness Probe Type: HTTP Request
### Step-04-01: Review Liveness Probe Type: HTTP Request
- **File Name:** `02-liveness-probe-HTTP-Request/05-UserMgmtWebApp-Deployment.yaml`
```yaml
          # Liveness Probe HTTP Request
          livenessProbe:
            httpGet:
              path: /login
              port: 8080
              httpHeaders:
              - name: Custom-Header
                value: Awesome          
            initialDelaySeconds: 60 # initialDelaySeconds field tells  the kubelet that it should wait 60 seconds before performing the first probe. 
            periodSeconds: 10 # periodSeconds field specifies kubelet should perform a liveness probe every 10 seconds. 
            failureThreshold: 3 # Default Value
            successThreshold: 1 # Default value
                    
```

### Step-04-02: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f 02-liveness-probe-HTTP-Request

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

### Step-04-03: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f 02-liveness-probe-HTTP-Request
```



## Step-05: Liveness Probe Type: TCP Request
### Step-05-01: Review Liveness Probe Type: TCP Request
- **File Name:** `03-liveness-probe-TCP-Request/05-UserMgmtWebApp-Deployment.yaml`
```yaml
          # Liveness Probe TCP request
          livenessProbe:
            tcpSocket:
              port: 8080
            initialDelaySeconds: 60 # initialDelaySeconds field tells  the kubelet that it should wait 60 seconds before performing the first probe. 
            periodSeconds: 10 # periodSeconds field specifies kubelet should perform a liveness probe every 10 seconds. 
            failureThreshold: 3 # Default Value
            successThreshold: 1 # Default value
                    
```

### Step-05-02: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f 03-liveness-probe-TCP-Request

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

### Step-05-03: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f 03-liveness-probe-TCP-Request
```


