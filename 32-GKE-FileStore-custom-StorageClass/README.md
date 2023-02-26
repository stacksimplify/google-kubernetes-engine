---
title: GKE Storage with GCP File Store - Custom StorageClass
description: Use GCP File Store for GKE Workloads with Custom StorageClass
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

## Step-01: Introduction
- GKE Storage with GCP File Store - Custom StorageClass


## Step-02: Enable Filestore CSI driver	(If not enabled)
- Go to Kubernetes Engine -> standard-cluster-private -> Details -> Features -> Filestore CSI driver	
- Click on Checkbox **Enable Filestore CSI Driver**
- Click on **SAVE CHANGES**

## Step-03: Verify if Filestore CSI Driver enabled
```t
# Verify Filestore CSI Daemonset in kube-system namespace
kubectl -n kube-system get ds | grep file
Observation: 
1. You should find the Daemonset with name "filestore-node"

# Verify Filestore CSI Daemonset pods in kube-system namespace
kubectl -n kube-system get pods | grep file
Observation: 
1. You should find the pods with name "filestore-node-*"
```

## Step-04: Existing Storage Class
- After you enable the Filestore CSI driver, GKE automatically installs the following StorageClasses for provisioning Filestore instances:
- **standard-rwx:** using the Basic HDD Filestore service tier
- **premium-rwx:** using the Basic SSD Filestore service tier
```t
# Default Storage Class created as part of FileStore CSI Enablement
kubectl get sc
Observation: Below two storage class will be created by default
standard-rwx
premium-rwx 
```

## Step-05: 00-filestore-storage-class.yaml
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: filestore-storage-class
provisioner: filestore.csi.storage.gke.io # File Store CSI Driver
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
parameters:
  tier: standard # Allowed values standard, premium, or enterprise
  network: default # The network parameter can be used when provisioning Filestore instances on non-default VPCs. Non-default VPCs require special firewall rules to be set up.
```

## Step-06: Other YAML files are same as previous section
- Other YAML files are same as previous section
- 01-filestore-pvc.yaml
- 02-write-to-filestore-pod.yaml
- 03-myapp1-deployment.yaml
- 04-loadBalancer-service.yaml

## Step-07: Deploy kube-manifests
```t
# Deploy kube-manifests
kubectl apply -f kube-manifests/

# List Storage Class
kubectl get sc

# List PVC
kubectl get pvc

# List PV
kubectl get pv

# List Pods
kubectl get pods
``` 

## Step-08: Verify GCP Cloud FileStore Instance
- Go to FileStore -> Instances
- Click on **Instance ID: pvc-27cd5c27-0ed0-48d1-bc5f-925adfb8495f**
- **Note:** Instance ID dynamically generated, it can be different in your case starting with pvc-*

## Step-09: Connect to filestore write app Kubernetes pods and Verify
```t
# FileStore write app - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty filestore-writer-app  -- /bin/sh
cd /data
ls
tail -f myapp1.txt
exit
```

## Step-10: Connect to myapp1 Kubernetes pods and Verify
```t
# List Pods
kubectl get pods 

# myapp1 POD1 - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty myapp1-deployment-5d469f6478-2kp97 -- /bin/sh
cd /usr/share/nginx/html/filestore
ls
tail -f myapp1.txt
exit

# myapp1 POD2 - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty myapp1-deployment-5d469f6478-2kp97  -- /bin/sh
cd /usr/share/nginx/html/filestore
ls
tail -f myapp1.txt
exit
```

## Step-11: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<EXTERNAL-IP-OF-GET-SERVICE-OUTPUT>/filestore/myapp1.txt
http://35.232.145.61/filestore/myapp1.txt
curl http://35.232.145.61/filestore/myapp1.txt
```


## Step-12: Clean-Up
```t
# Delete Kubernetes Objects
kubectl delete -f kube-manifests/

# Verify if FileStore Instance is deleted
Go to -> FileStore -> Instances
```