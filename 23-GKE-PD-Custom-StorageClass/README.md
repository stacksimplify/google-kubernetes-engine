---
title: GKE Persistent Disks Custom StorageClass 
description: Use Custom storageclass to provision Google Disks for Kubernetes Workloads
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
- **Feaute-1:** Create custom Kubernetes StorageClass instead of using predefined one in GKE Cluster. custom storage class `gke-pd-standard-rwo-sc`
- **Feature-2:** Test `allowVolumeExpansion: true` in Storage Class
- **Feature-3:** Use `reclaimPolicy: Retain` in Storage Class and Test it 

## Step-02: List Kubernetes Storage Classes in GKE Cluster
```t
# List Storage Classes
kubectl get sc
```

## Step-03: 00-storage-class.yaml
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata: 
  name: gke-pd-standard-rwo-sc
provisioner: pd.csi.storage.gke.io
volumeBindingMode: WaitForFirstConsumer 
allowVolumeExpansion: true
reclaimPolicy: Retain 
parameters:
  type: pd-balanced

# STORAGE CLASS 
# 1. A StorageClass provides a way for administrators 
# to describe the "classes" of storage they offer.
# 2. Here we are offering GCP PD Storage for GKE Cluster
```

## Step-04: 01-persistent-volume-claim.yaml
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec: 
  accessModes:
    - ReadWriteOnce
  storageClassName: gke-pd-standard-rwo-sc
  resources: 
    requests:
      storage: 4Gi
```


## Step-05: Other Kubernetes YAML Manifests
- No changes to other Kubernetes YAML Manifests
- They are same as previous section
- 02-UserManagement-ConfigMap.yaml
- 03-mysql-deployment.yaml
- 04-mysql-clusterip-service.yaml
- 05-UserMgmtWebApp-Deployment.yaml
- 06-UserMgmtWebApp-LoadBalancer-Service.yaml

## Step-06: Deploy kube-manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests/

# List Storage Classes
kubectl get sc
Observation: 
1. You should find the new custom storage class object created with name as "gke-pd-standard-rwo-sc"

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

## Step-07: Verify Persistent Disks
- Go to Compute Engine -> Storage -> Disks
- Search for `4GB` Persistent Disk
- **Observation:** You should see the disk type as **Balanced persistent disk**



## Step-08: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<ExternalIP-from-get-service-output>
Username: admin101
Password: password101

# Create New User (Used for testing  `allowVolumeExpansion: true` Option)
Username: admin102
Password: password102
First Name: fname102
Last Name: lname102
Email Address: admin102@stacksimplify.com
Social Security Address: ssn102
```

## Step-09: Update 01-persistent-volume-claim.yaml from 4Gi to 8Gi
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec: 
  accessModes:
    - ReadWriteOnce
  storageClassName: gke-pd-standard-rwo-sc
  resources: 
    requests:
      #storage: 4Gi # Commment at Step-09
      storage: 8Gi # UnCommment at Step-09
```

## Step-10: Deploy updated kube-manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests/

# List PVC
kubectl get pvc
Observation:
1. Wait for 2 to 3 mins and automatically CAPACITY value changes from 4Gi to 8Gi

# List PV
kubectl get pv
Observation:
1. Wait for 2 to 3 mins and automatically CAPACITY value changes from 4Gi to 8Gi

# Access Application
http://<ExternalIP-from-get-service-output>
Username: admin101
Password: password101
Observation:
1. No impact to underlying MySQL Database data.
2. VolumeExpansion is seamless without impacting the real data. 
3. We should find the two users which are present before VolumeExpansion as-is.
```
## Step-11: Verify Persistent Disks
- Go to Compute Engine -> Storage -> Disks
- Search for `8GB` Persistent Disk, as 4GB disk expaned to 8GB now.
- **Observation:** You should see the disk type as **Balanced persistent disk**


## Step-12: Verify reclaimPolicy: Retain
```t
# Delete kube-manifests
kubectl delete -f kube-manifests/

# List Storage Class
kubectl get sc
Observation:
1. Custom storage class deleted

# List PVC
kubectl get pvc
Observation:
1. PVC deleted

# List PV
kubectl get pv
Observation:
1. PV still present
2. PV STATUS will be in "Released", not used by anyoe.
```

## Step-13: Verify Persistent Disks
- Go to Compute Engine -> Storage -> Disks
- Search for `8GB` Persistent Disk.
- **Observation:** You should see the disk is still present even after all kube-manifests (storageclass, pvc) all deleted.
- This is due to we have used **reclaimPolicy: Retain** in Custom Storage Class


## Step-14: Clone Persistent Disk
- **Question:** Why we are cloning the disk ?
- **Answer:** In the next demo, we are going use the **pre-existing persistent disk** in our demo. For that purpose we are cloning it. 
- Go to Compute Engine -> Storage -> Disks
- Search for `8GB` Persistent Disk.
- Click on **Clone Disk**
- **Name:** preexisting-pd
- **Description:** preexisting-pd Demo with GKE
- **Location:** Single
- **Snapshot Schedule:** UNCHECK
- Click on **CREATE**

## Step-15: Delete Retained Persistent Disk from this Demo
- Go to Compute Engine -> Storage -> Disks
- Search for `8GB` Persistent Disk.
- **Disk Name:**  pvc-3f2c1daa-122d-4bdb-a7b6-b9943631cc14
- Click on **DELETE DISK**
```t
# List PV
kubectl get pv

# Delete  PV 
kubectl delete pv pvc-3f2c1daa-122d-4bdb-a7b6-b9943631cc14 

# List PV
kubectl get pv
```

## Step-16: Change PVC 8Gi to 4Gi: 01-persistent-volume-claim.yaml
- Change PVC 8Gi to 4Gi so that `kube-manifests` will be demo ready for students. 
```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
spec: 
  accessModes:
    - ReadWriteOnce
  storageClassName: gke-pd-standard-rwo-sc
  resources: 
    requests:
      storage: 4Gi # Commment at Step-09
      #storage: 8Gi # UnCommment at Step-09
```


## Reference
- [Using the Compute Engine persistent disk CSI Driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver)
