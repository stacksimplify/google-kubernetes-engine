---
title: GCP Google Kubernetes Engine GKE Private Cluster
description: Implement GCP Google Kubernetes Engine GKE Private Cluster
---

## Step-01: Introduction
- Create GKE Private Cluster
- Create Cloud NAT
- Deploy Sample App and Test
- Perform Authorized Network Tests
 
## Step-02: Create Standard GKE Cluster 
- Go to Kubernetes Engine -> Clusters -> CREATE
- Select **GKE Standard -> CONFIGURE**
- **Cluster Basics**
  - **Name:** standard-cluster-private-1
  - **Location type:** Regional
  - **Zone:** us-central1-a, us-central1-b, us-central1-c
  - **Release Channel**
    - **Release Channel:** Rapid Channel
    - **Version:** LATEST AVAIALABLE ON THAT DAY
  - REST ALL LEAVE TO DEFAULTS
- **NODE POOLS: default-pool**
- **Node pool details**
  - **Name:** default-pool
  - **Number of Nodes (per Zone):** 1
- **Nodes: Configure node settings** 
  - **Image type:** Containerized Optimized OS
  - **Machine configuration**
    - **GENERAL PURPOSE SERIES:** e2
    - **Machine Type:** e2-small
  - **Boot disk type:** standard persistent disk
  - **Boot disk size(GB):** 20
  - **Enable Nodes on Spot VMs:** CHECKED
- **Node Networking:** REVIEW AND LEAVE TO DEFAULTS    
- **Node Security:** 
  - **Access scopes:** Allow full access to all Cloud APIs
  - REST ALL REVIEW AND LEAVE TO DEFAULTS
- **Node Metadata:** REVIEW AND LEAVE TO DEFAULTS
- **CLUSTER** 
  - **Automation:** REVIEW AND LEAVE TO DEFAULTS
  - **Networking:** 
    - **Network Access:** Private Cluster
    - **Access control plane using its external IP address:** BY DEFAULT CHECKED
      - **Important Note:** Disabling this option locks down external access to the cluster control plane. There is still an external IP address used by Google for cluster management purposes, but the IP address is not accessible to anyone. This setting is  permanent
    - **Enable Control Plane Global Access:** CHECKED
    - **Control Plane IP Range:** 172.16.0.0/28
    - **CHECK THIS BOX: Enable Dataplane V2** CHECK IT - IN FUTURE VERSIONS IT WILL BE BY DEFAULT ENABLED
  - **Security:** REVIEW AND LEAVE TO DEFAULTS
    - **CHECK THIS BOX: Enable Workload Identity** IN FUTURE VERSIONS IT WILL BE BY DEFAULT ENABLED
  - **Metadata:** REVIEW AND LEAVE TO DEFAULTS
  - **Features:** REVIEW AND LEAVE TO DEFAULTS
    - **Enable Compute Engine Persistent Disk CSI Driver:** SHOULD BE CHECKED BY DEFAULT - VERIFY
    - **Enable File Store CSI Driver:** CHECKED 
- CLICK ON **CREATE**

## Step-03: Review kube-manifests: 01-kubernetes-deployment.yaml
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
          imagePullPolicy: Always            
```

## Step-04: Review kube-manifest: 02-kubernetes-loadbalancer-service.yaml
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

## Step-05: Deploy Kubernetes Manifests
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123

# Change Directory
cd 20-GKE-Private-Cluster

# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests/

# Verify Pods 
kubectl get pods 
Observation: SHOULD FAIL - UNABLE TO DOWNLOAD DOCKER IMAGE FROM DOCKER HUB

# Describe Pod
kubectl describe pod <POD-NAME>

# Clean-Up
kubectl delete -f kube-manifests/
```

## Step-06: Create Cloud NAT
- Go to Network Services -> CREATE CLOUD NAT GATEWAY
- **Gateway Name:** gke-us-central1-default-cloudnat-gw
- **Select Cloud Router:** 
  - **Network:** default
  - **Region:** us-central1
  - **Cloud Router:** CREATE NEW ROUTER
    - **Name:** gke-us-central1-cloud-router
    - **Description:** GKE Cloud Router Region us-central1
    - **Network:** default (POPULATED by default)
    - **Region:** us-central1 (POPULATED by default)
    - **BGP Peer keepalive interval:** 20 seconds (LEAVE TO DEFAULT)
    - Click on **CREATE**
- **Cloud NAT Mapping:** LEAVE TO DEFAULTS
- **Destination (external):** LEAVE TO DEFAULTS
- **Stackdriver logging:**  LEAVE TO DEFAULTS
- **Port allocation:** 
  - CHECK **Enable Dynamic Port Allocation**
- **Timeouts for protocol connections:** LEAVE TO DEFAULTS
- CLICK on **CREATE**  

## Step-07: Deploy Kubernetes Manifests
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123

# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests

# Verify Pods 
kubectl get pods 
Observation: SHOULD BE ABLE TO DOWNLOAD THE DOCKER IMAGE

# List Services
kubectl get svc

# Access Application
http://<External-IP>

# Clean-Up
kubectl delete -f kube-manifests
```

## Step-08: Authorized Network Test1: My Network
- Goto -> standard-cluster-private-1 -> DETAILS -> NETWORKING
- Control plane authorized networks	-> EDIT
- **Enable control plane authorized networks:** CHECKED
- CLICK ON **ADD AUTHORIZED NETWORK**
- **NAME:** MY-NETWORK-1
- **NETWORK:** 10.10.10.0/24 
- Click on **DONE**
- Click on **SAVE CHANGES**
```t
# List Kubernetes Nodes
kubectl get nodes
Observation:
1. Access to GKE API Service from our local desktop kubectl cli is lost
2. Access to GKE API Service is now allowed only from "10.10.10.0/24" network
3. In short even though our GKE API Server has Internet enabled endpoint, its access is restricted to specific network of IPs

## Sample Output
Kalyan-Mac-mini:google-kubernetes-engine kalyan$ kubectl get nodes
Unable to connect to the server: dial tcp 34.70.169.161:443: i/o timeout
Kalyan-Mac-mini:google-kubernetes-engine kalyan$ 
```

## Step-09: Authorized Network Test2: My Desktop
- Go to link [whatismyip](https://www.whatismyip.com/) and get desktop public IP 
- Goto -> standard-cluster-private-1 -> DETAILS -> NETWORKING
- Control plane authorized networks	-> EDIT
- **Enable control plane authorized networks:** CHECKED
- CLICK ON **ADD AUTHORIZED NETWORK**
- **NAME:** MY-DESKTOP-1
- **NETWORK:** 10.10.10.0/24 
- Click on **DONE**
- Click on **SAVE CHANGES**
```t
# List Kubernetes Nodes
kubectl get nodes
Observation:
1. Access to GKE API Service from our local desktop kubectl cli should be success

## Sample Output
Kalyans-Mac-mini:google-kubernetes-engine kalyan$ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE   VERSION
gke-standard-cluster-pri-default-pool-90b1f67b-4z71   Ready    <none>   55m   v1.24.3-gke.900
gke-standard-cluster-pri-default-pool-90b1f67b-6xn6   Ready    <none>   55m   v1.24.3-gke.900
gke-standard-cluster-pri-default-pool-90b1f67b-dggg   Ready    <none>   55m   v1.24.3-gke.900
Kalyans-Mac-mini:google-kubernetes-engine kalyan$ 
```

## Step-10: Authorized Network Test2: Delete both network rules (Roll back to old state)
- Goto -> standard-cluster-private-1 -> DETAILS -> NETWORKING
- Control plane authorized networks	-> EDIT
- **Enable control plane authorized networks:** UN-CHECKED
- AUTHORIZED NETWORKS -> DELETE -> MY-NETWORK-1, MY-DESKTOP-1
- Click on **SAVE CHANGES**
```t
# List Kubernetes Nodes
kubectl get nodes
Observation:
1. Access to GKE API Service from our local desktop kubectl cli should be success

## Sample Output
Kalyans-Mac-mini:google-kubernetes-engine kalyan$ kubectl get nodes
NAME                                                  STATUS   ROLES    AGE   VERSION
gke-standard-cluster-pri-default-pool-90b1f67b-4z71   Ready    <none>   55m   v1.24.3-gke.900
gke-standard-cluster-pri-default-pool-90b1f67b-6xn6   Ready    <none>   55m   v1.24.3-gke.900
gke-standard-cluster-pri-default-pool-90b1f67b-dggg   Ready    <none>   55m   v1.24.3-gke.900
Kalyans-Mac-mini:google-kubernetes-engine kalyan$ 
```

## Additional Reference
- [GKE Private Cluster with Terraform](https://github.com/GoogleCloudPlatform/gke-private-cluster-demo)