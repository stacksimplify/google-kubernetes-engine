---
title: GCP Google Kubernetes Engine GKE NodePort Service
description: Implement GCP Google Kubernetes Engine GKE NodePort Service
---

## Step-00: Pre-requisites
1. Verify if GKE Cluster is created
2. Verify if kubeconfig for kubectl is configured in your local terminal
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>

# Replace Values CLUSTER-NAME, ZONE, PROJECT
gcloud container clusters get-credentials standard-public-cluster-1 --region us-central1 --project kdaida123

# List GKE Kubernetes Worker Nodes
kubectl get nodes

# List GKE Kubernetes Worker Nodes with -o wide option
kubectl get nodes -o wide
Observation: 
1. You should see External-IP Address (Public IP accesible via internet)
2. That is the key thing for testing the Kubernetes NodePort Service on GKE Cluster
```
## Step-01: Introduction
- Implement Kubernetes NodePort Service 

## Step-02: 01-kubernetes-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment 
metadata: #Dictionary
  name: myapp1-deployment
spec: # Dictionary
  replicas: 2
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
```

## Step-03: 02-kubernetes-nodeport-service.yaml
- If you don't speciy `nodePort: 30080` it will dynamically assign one port from range `30000-32768`
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: myapp1-nodeport-service
spec:
  type: NodePort # clusterIP, # NodePort, # LoadBalancer, # ExternalName
  selector:
    app: myapp1
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
      nodePort: 30080 # NodePort (Optional)(Node Port Range: 30000-32768)
```


## Step-04: Deply Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests

# List Deployments
kubectl get deploy

# List Pods
kubectl get po

# List Services
kubectl get svc
```

## Step-05: Access Application
```t
# List Kubernetes Worker Node with -0 wide
kubectl get nodes -o wide
Observation: 
1. Make a note of any one Node External-IP (Public IP Address)

# Access Application
http://<NODE-EXTERNAL-IP>:<NodePort>
http://104.154.52.12:30080
Observation:
1. This should fail
```

## Step-06: Create Firewall Rule
```t
# Create Firewall Rule
gcloud compute firewall-rules create fw-rule-gke-node-port \
    --allow tcp:NODE_PORT

# Replace NODE_PORT
gcloud compute firewall-rules create fw-rule-gke-node-port \
    --allow tcp:30080   

# List Firewall Rules
gcloud compute firewall-rules list    
```

## Step-07:Access Application
```t
# List Kubernetes Worker Node with -0 wide
kubectl get nodes -o wide
Observation: 
1. Make a note of any one Node External-IP (Public IP Address)

# Access Application
http://<NODE-EXTERNAL-IP>:<NodePort>
http://104.154.52.12:30080
Observation:
1. This should Pass
```



## Step-08: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests

# Delete NodePort Service Firewall Rule
gcloud compute firewall-rules delete fw-rule-gke-node-port

# List Firewall Rules
gcloud compute firewall-rules list 
```


