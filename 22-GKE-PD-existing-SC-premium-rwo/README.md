---
title: GKE Persistent Disks Existing StorageClass premium-rwo
description: Use existing storageclass premium-rwo in Kubernetes Workloads
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
- Understand Kubernetes Objects
01. Kubernetes PersistentVolumeClaim
02. Kubernetes ConfigMap
03. Kubernetes Deployment
04. Kubernetes Volumes
05. Kubernetes Volume Mounts
06. Kubernetes Environment Variables
07. Kubernetes ClusterIP Service
08. Kubernetes Init Containers
09. Kubernetes Service of Type LoadBalancer
10. Kubernetes StorageClass 

- Use the predefined Storage class `premium-rwo`
- By default, dynamically provisioned PersistentVolumes use the default StorageClass and are backed by `standard hard disks`. 
- If you need faster SSDs, you can use the `premium-rwo` storage class from the Compute Engine persistent disk CSI Driver to provision your volumes. 
- This can be done by setting the storageClassName field to `premium-rwo` in your PersistentVolumeClaim 
- `premium-rwo Storage Class` will provision `SSD Persistent Disk`

## Step-02: List Kubernetes Storage Classes in GKE Cluster
```t
# List Storage Classes
kubectl get sc
```

## Step-03: 01-persistent-volume-claim.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec: 
  accessModes:
    - ReadWriteOnce
  storageClassName: premium-rwo 
  resources: 
    requests:
      storage: 4Gi
```

## Step-04: Other Kubernetes YAML Manifests
- No changes to other Kubernetes YAML Manifests
- They are same as previous section
1. 01-persistent-volume-claim.yaml
2. 02-UserManagement-ConfigMap.yaml
3. 03-mysql-deployment.yaml
4. 04-mysql-clusterip-service.yaml
5. 05-UserMgmtWebApp-Deployment.yaml
6. 06-UserMgmtWebApp-LoadBalancer-Service.yaml

## Step-05: Deploy kube-manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests/

# List Storage Classes
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

## Step-06: Verify Persistent Disks
- Go to Compute Engine -> Storage -> Disks
- Search for `4GB` Persistent Disk
- **Observation:** You should see the disk type as **SSD persistent disk**


## Step-07: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<ExternalIP-from-get-service-output>
Username: admin101
Password: password101
```

## Step-08: Clean-Up
```t
# Delete kube-manifests
kubectl delete -f kube-manifests/
```

## Reference
- [Using the Compute Engine persistent disk CSI Driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver)