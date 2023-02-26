---
title: GKE Persistent Disks - Volume Clone
description: Use Google Disks Volume Clone for GKE Workloads
---


## Step-00: Pre-requisites
1. Verify if GKE Cluster is created
2. Verify if kubeconfig for kubectl is configured in your local terminal
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>

# Replace Values CLUSTER-NAME, ZONE, PROJECT
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123
```
3. Feature: Compute Engine persistent disk CSI Driver
  - Verify the Feature **Compute Engine persistent disk CSI Driver** enabled in GKE Cluster. 
  - This is required for mounting the Google Compute Engine Persistent Disks to Kubernetes Workloads in GKE Cluster.


## Step-01: Introduction
- Understand how to implement cloned Disks in GKE

## Step-02:  Kubernetes YAML Manifests
- **Project Folder:** 01-kube-manifests
- No changes to Kubernetes YAML Manifests, same as Section `21-GKE-PD-existing-SC-standard-rwo`
- 01-persistent-volume-claim.yaml
- 02-UserManagement-ConfigMap.yaml
- 03-mysql-deployment.yaml
- 04-mysql-clusterip-service.yaml
- 05-UserMgmtWebApp-Deployment.yaml
- 06-UserMgmtWebApp-LoadBalancer-Service.yaml

## Step-03: Deploy kube-manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f 01-kube-manifests/

# List Storage Class
kubectl get sc

# List PVC
kubectl get pvc

# List PV
kubectl get pv

# List ConfigMaps
kubectl get configmap

# List Deployments
kubectl get deploy

# List Pods
kubectl get pods

# List Services
kubectl get svc

# Verify Pod Logs
kubectl get pods
kubectl logs -f <USERMGMT-POD-NAME>
kubectl logs -f usermgmt-webapp-6ff7d7d849-7lrg5
```

## Step-04: Verify Persistent Disks
- Go to Compute Engine -> Storage -> Disks
- Search for `4GB` Persistent Disk
- **Observation:** Review the below items
  - **Zones:** us-central1-c
  - **Type:** Balanced persistent disk
  - **In use by:** gke-standard-cluster-1-default-pool-db7b638f-j5lk

## Step-05: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<ExternalIP-from-get-service-output>
Username: admin101
Password: password101

# Create New User admin102
Username: admin102
Password: password102
First Name: fname102
Last Name: lname102
Email Address: admin102@stacksimplify.com
Social Security Address: ssn102

# Create New User admin103
Username: admin103
Password: password103
First Name: fname103
Last Name: lname103
Email Address: admin103@stacksimplify.com
Social Security Address: ssn103
```

## Step-06: Volume Clone: 01-podpvc-clone.yaml
- **Project Folder:** 02-Use-Cloned-Volume-kube-manifests
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: podpvc-clone
spec:
  dataSource:
    name: mysql-pv-claim # the name of the source PersistentVolumeClaim that you created as part of UMS Web App
    kind: PersistentVolumeClaim
  accessModes:
    - ReadWriteOnce
  storageClassName: standard-rwo  # same as the StorageClass of the source PersistentVolumeClaim.   
  resources:
    requests:
      storage: 4Gi # the amount of storage to request, which must be at least the size of the source PersistentVolumeClaim
```

## Step-07: 03-mysql-deployment.yaml
- **Change-1:** Change the `claimName: mysql-pv-claim` to `claimName: podpvc-clone`
- 
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql2
spec: 
  replicas: 1
  selector:
    matchLabels:
      app: mysql2
  strategy:
    type: Recreate 
  template: 
    metadata: 
      labels: 
        app: mysql2
    spec: 
      containers:
        - name: mysql2
          image: mysql:8.0
          env:
            - name: MYSQL_ROOT_PASSWORD
              value: dbpassword11
          ports:
            - containerPort: 3306
              name: mysql    
          volumeMounts:
            - name: mysql-persistent-storage
              mountPath: /var/lib/mysql    
            - name: usermanagement-dbcreation-script
              mountPath: /docker-entrypoint-initdb.d #https://hub.docker.com/_/mysql Refer Initializing a fresh instance                                         
      volumes: 
        - name: mysql-persistent-storage
          persistentVolumeClaim:
            #claimName: mysql-pv-claim
            claimName: podpvc-clone
        - name: usermanagement-dbcreation-script
          configMap:
            name: usermanagement-dbcreation-script2
```

## Step-08:  Kubernetes YAML Manifests
- **Project Folder:** 02-Use-Cloned-Volume-kube-manifests
- No changes to Kubernetes YAML Manifests, same as Section `21-GKE-PD-existing-SC-standard-rwo`
- For all the resource names and labels append with 2 (Example: mysql to mysql2, usermgmt-webapp to usermgmt-webapp2)
- 02-UserManagement-ConfigMap.yaml
- 03-mysql-deployment.yaml
- 04-mysql-clusterip-service.yaml
- 05-UserMgmtWebApp-Deployment.yaml
- 06-UserMgmtWebApp-LoadBalancer-Service.yaml

## Step-09: Deploy kube-manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f 02-Use-Cloned-Volume-kube-manifests/

# List Storage Class
kubectl get sc

# List PVC
kubectl get pvc

# List PV
kubectl get pv

# List ConfigMaps
kubectl get configmap

# List Deployments
kubectl get deploy

# List Pods
kubectl get pods

# List Services
kubectl get svc

# Verify Pod Logs
kubectl get pods
kubectl logs -f <USERMGMT-POD-NAME>
kubectl logs -f usermgmt-webapp2-6ff7d7d849-7lrg5
```

## Step-10: Verify Persistent Disks
- Go to Compute Engine -> Storage -> Disks
- Search for `4GB` Persistent Disk
- **Observation:** Review the below items
  - **Type:** Balanced persistent disk
  - **In use by:** gke-standard-cluster-1-default-pool-db7b638f-j5lk

## Step-11: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<ExternalIP-from-get-service-output>
Username: admin101
Password: password101

Observation:
1. You should see both "admin102" and "admin103" users already present.
2. This is because we have used the cloned disk from "01-kube-manifests"
```

## Step-12: Clean-Up
```t
# Delete Kubernetes Objects
kubectl delete -f 01-kube-manifests -f 02-Use-Cloned-Volume-kube-manifests
```


```t
# Reference
https://kubernetes.io/docs/tasks/configure-pod-container/assign-pods-nodes/

# Get Nodes
kubectl get nodes 

# Show Node Labels
kubectl get nodes --show-labels

# Label Node
kubectl label nodes <your-node-name> nodetype=db
kubectl label nodes gke-standard-cluster-pri-default-pool-4f7ab141-p0gz nodetype=db

# Show Node Labels
kubectl get nodes --show-labels
```
