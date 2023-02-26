---
title: GCP Google Kubernetes Engine Autopilot Cluster
description: Implement GCP Google Kubernetes Engine GKE Autopilot Cluster
---

## Step-01: Introduction
- Create GKE Autopilot Cluster
- Understand in detail about GKE Autopilot cluster

## Step-02: Pre-requisite: Verify if Cloud NAT Gateway created 
- Verify if Cloud NAT Gateway created in `Region:us-central1` where you are planning to create GKE Autopilot Private Cluster
- This is required for Workload in Private subnets to connect to Internet.  
- Primarily to Connect to Docker Hub to pull the Docker Images
- Go to Network Services -> Cloud NAT

## Step-03: Create GKE Autopilot Private Cluster
- Go to Kubernetes Engine -> Clusters -> **CREATE**
- Create Cluster -> GKE Autopilot -> **CONFIGURE**
- **Name:** autopilot-cluster-private-1
- **Region:** us-central1
- **Network access:** Private Cluster
- **Access control plane using its external IP address:** CHECK
- **Control plane ip range:** 172.18.0.0/28
- **Enable control plane authorized networks:** CHECK
- **Authorized networks:** 
  - **Name:** internet-access
  - **Network:** 0.0.0.0/0
  - Click on **DONE**
- **Network:** default  (LEAVE TO DEFAULTS)
- **Node subnet:** default (LEAVE TO DEFAULTS)
- **Cluster default pod address range:** /17 (LEAVE TO DEFAULTS)
- **Service Address range:** /22 (LEAVE TO DEFAULTS)
- **Release Channel:** Regular Channel (Default)
- REST ALL LEAVE TO DEFAULTS
- Click on **CREATE** 

## Step-04: Configure kubectl for kubeconfig
```t
# Configure kubectl for kubeconfig
gcloud container clusters get-credentials CLUSTER-NAME --region REGION --project PROJECT-NAME

# Replace values CLUSTER-NAME, REGION, PROJECT-NAME
gcloud container clusters get-credentials autopilot-cluster-private-1 --region us-central1 --project kdaida123

# List Kubernetes Nodes
kubectl get nodes
kubectl get nodes -o wide
```

## Step-05: Review Kubernetes Manifests
### Step-05-01: 01-kubernetes-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment 
metadata: #Dictionary
  name: myapp1-deployment
spec: # Dictionary
  replicas: 5 
  selector:
    matchLabels:
      app: myapp1
  template:  
    metadata: # Dictionary
      name: myapp1-pod
      labels: # Dictionary
        app: myapp1  # Key value pairs
    spec:
      containers: # List
        - name: myapp1-container
          image: stacksimplify/kubenginx:1.0.0
          ports: 
            - containerPort: 80  
          resources:
            requests:
              memory: "128Mi" # 128 MebiByte is equal to 135 Megabyte (MB)
              cpu: "200m" # `m` means milliCPU
            limits:
              memory: "256Mi"
              cpu: "400m"  # 1000m is equal to 1 VCPU core                           
```
### Step-05-02: 02-kubernetes-loadbalancer-service.yaml
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: myapp1-lb-service
spec:
  type: LoadBalancer # ClusterIp, # NodePort
  selector:
    app: myapp1
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
```

## Step-06: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests

# List Deployments
kubectl get deploy

# List Pods
kubectl get pods

# List Services
kubectl get svc

# Access Application
http://<EXTERNAL-IP-OF-GET-SERVICE-OUTPUT>
```

## Step-07: Scale your Application
```t
# Scale your Application
kubectl scale --replicas=15 deployment/myapp1-deployment

# List Pods
kubectl get pods

# List Nodes
kubectl get nodes
```

## Step-08: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests

# Delete GKE Autopilot Cluster 
# NOTE: Dont delete this cluster, as we are going to use this in next demo.
Go to Kubernetes Engine > Clusters -> autopilot-cluster-private-1 -> DELETE
```


## References
- https://cloud.google.com/kubernetes-engine/docs/concepts/autopilot-overview#default_container_resource_requests
- https://cloud.google.com/kubernetes-engine/quotas#limits_per_cluster