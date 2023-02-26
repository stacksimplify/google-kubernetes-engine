---
title: GKE Storage with GCP File Store - Backup and Restore
description: Use GCP File Store for GKE Workloads - Implement Backup and Restore
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
- GKE Storage with GCP File Store 
- Implement Backups is `VolumeSnapshotClass` and `VolumeSnapshot`
- Implement Restore of FileStore in myapp2 Application and Verify


## Step-02: YAML files are same as first FileStore Demo
- **Project Folder:** 01-myapp1-kube-manifests
- YAML files are same as first FileStore Demo
- 01-filestore-pvc.yaml
- 02-write-to-filestore-pod.yaml
- 03-myapp1-deployment.yaml
- 04-loadBalancer-service.yaml

## Step-03: Deploy 01-myapp1-kube-manifests and Verify
```t
# Deploy 01-myapp1-kube-manifests
kubectl apply -f 01-myapp1-kube-manifests

# List Storage Class
kubectl get sc

# List PVC
kubectl get pvc

# List PV
kubectl get pv

# List Pods
kubectl get pods
``` 

## Step-04: Verify GCP Cloud FileStore Instance
- Go to FileStore -> Instances
- Click on **Instance ID: pvc-27cd5c27-0ed0-48d1-bc5f-925adfb8495f**
- **Note:** Instance ID dynamically generated, it can be different in your case starting with pvc-*

## Step-05: Connect to filestore write app Kubernetes pods and Verify
```t
# FileStore write app - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty filestore-writer-app  -- /bin/sh
cd /data
ls
tail -f myapp1.txt
exit
```

## Step-06: Connect to myapp1 Kubernetes pods and Verify
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

## Step-07: Access Application
```t
# List Services
kubectl get svc

# myapp1 - Access Application
http://<EXTERNAL-IP-OF-GET-SERVICE-OUTPUT>/filestore/myapp1.txt
http://35.232.145.61/filestore/myapp1.txt
curl http://35.232.145.61/filestore/myapp1.txt
```


## Step-08: Volume Backup: 01-VolumeSnapshotClass.yaml
- **Project Folder:** 02-volume-backup-kube-manifests
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshotClass
metadata:
  name: csi-gcp-filestore-backup-snap-class
driver: filestore.csi.storage.gke.io
parameters:
  type: backup
deletionPolicy: Delete
```

## Step-09: Volume Backup: 02-VolumeSnapshot.yaml
- **Project Folder:** 02-volume-backup-kube-manifests
```yaml
apiVersion: snapshot.storage.k8s.io/v1
kind: VolumeSnapshot
metadata:
  name: myapp1-volume-snapshot
spec:
  volumeSnapshotClassName: csi-gcp-filestore-backup-snap-class
  source:
    persistentVolumeClaimName: gke-filestore-pvc
```

## Step-10: Volume Backup: Deploy 02-volume-backup-kube-manifests and Verify
```t
# Deploy 02-volume-backup-kube-manifests
kubectl apply -f 02-volume-backup-kube-manifests

# List VolumeSnapshotClass
kubectl get volumesnapshotclass

# Describe VolumeSnapshotClass
kubectl describe volumesnapshotclass csi-gcp-filestore-backup-snap-class

# List VolumeSnapshot
kubectl get volumesnapshot

# Describe VolumeSnapshot
kubectl describe volumesnapshot myapp1-volume-snapshot
```

## Step-11: Volume Backup: Verify GCP Cloud FileStore Backups
- Go to FileStore -> Backups
- Observation: You should find the Backup with name `snapshot-<SOME-ID>` (Example: snapshot-b4f24bd7-649b-45bb-8a0a-2b09d5b0e631)

## Step-12: Volume Restore: 01-filestore-pvc.yaml
- **Project Folder:** 03-volume-restore-myapp2-kube-manifests
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: restored-filestore-pvc
spec:
  accessModes:
  - ReadWriteMany
  storageClassName: standard-rwx
  resources:
    requests:
      storage: 1Ti
  dataSource:
    kind: VolumeSnapshot
    name: myapp1-volume-snapshot
    apiGroup: snapshot.storage.k8s.io      
```

## Step-13: Volume Restore: 02-myapp2-deployment.yaml
- **Project Folder:** 03-volume-restore-myapp2-kube-manifests
```yaml
apiVersion: apps/v1
kind: Deployment 
metadata: #Dictionary
  name: myapp2-deployment
spec: # Dictionary
  replicas: 2
  selector:
    matchLabels:
      app: myapp2
  template:  
    metadata: # Dictionary
      name: myapp2-pod
      labels: # Dictionary
        app: myapp2  # Key value pairs
    spec:
      containers: # List
        - name: myapp2-container
          image: stacksimplify/kubenginx:1.0.0
          ports: 
            - containerPort: 80  
          volumeMounts:
            - name: persistent-storage
              mountPath: /usr/share/nginx/html/filestore
      volumes:
        - name: persistent-storage
          persistentVolumeClaim:
            claimName: restored-filestore-pvc    
```

## Step-14: Volume Restore: 03-myapp2-loadBalancer-service.yaml
- **Project Folder:** 03-volume-restore-myapp2-kube-manifests
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: myapp2-lb-service
spec:
  type: LoadBalancer # ClusterIp, # NodePort
  selector:
    app: myapp2
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
```

## Step-13: Volume Restore: Deploy 03-volume-restore-myapp2-kube-manifests and Verify
```t
# Deploy 03-volume-restore-myapp2-kube-manifests
kubectl apply -f 03-volume-restore-myapp2-kube-manifests

# List Storage Class
kubectl get sc

# List PVC
kubectl get pvc

# List PV
kubectl get pv

# List Pods
kubectl get pods

# Verify if new FileStore Instance is Created
Go to -> FileStore -> Instances
```

## Step-14: Volume Restore: Connect to myapp2 Kubernetes pods and Verify
```t
# List Pods
kubectl get pods 

# myapp1 POD1 - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty myapp2-deployment-6dccd6557-9x6dn -- /bin/sh
cd /usr/share/nginx/html/filestore
ls
tail -f myapp1.txt
exit

# myapp1 POD2 - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty myapp2-deployment-6dccd6557-mbbjm  -- /bin/sh
cd /usr/share/nginx/html/filestore
ls
tail -f myapp1.txt
exit
```

## Step-15: Volume Restore: Access Applications
```t
# List Services
kubectl get svc

# myapp1 - Access Application
http://<MYAPP1-EXTERNAL-IP-OF-GET-SERVICE-OUTPUT>/filestore/myapp1.txt
http://35.232.145.61/filestore/myapp1.txt


# myapp2 - Access Application
http://<MYAPP2-EXTERNAL-IP-OF-GET-SERVICE-OUTPUT>/filestore/myapp1.txt
http://34.71.145.41/filestore/myapp1.txt


OBSERVATION: 
1. For MyApp1, writer app is writing to FileStore so we get latest timestamp lines (many lines and file growing)
2. For MyApp2, we have restored it from backup, which means the number of lines present in file at the time of snapshot will be only displayed. 
3. KEY here is we are able to successfully use the filestore backup for our Kubernetes Workloads
```

## Step-16: Clean-Up
```t
# Delete Kubernetes Objects
kubectl delete -f 01-myapp1-kube-manifests -f 02-volume-backup-kube-manifests -f 03-volume-restore-myapp2-kube-manifests

# Verify if two FileStore Instances are deleted
Go to -> FileStore -> Instances

# Verify if FileStore Backup is deleted
Go to -> FileStore -> Backups
```