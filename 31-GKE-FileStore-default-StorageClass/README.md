---
title: GKE Storage with GCP File Store - Default StorageClass
description: Use GCP File Store for GKE Workloads with Default StorageClass
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
- GKE Storage with GCP File Store - Default StorageClass


## Step-02: Enable Filestore CSI driver	(If not enabled)
- Go to Kubernetes Engine -> standard-cluster-private-1 -> Details -> Features -> Filestore CSI driver	
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
- **enterprise-rwx**
- **enterprise-multishare-rwx**
```t
# Default Storage Class created as part of FileStore CSI Enablement
kubectl get sc
Observation: Below four storage class will be created by default
standard-rwx
premium-rwx 
enterprise-rwx
enterprise-multishare-rwx
```

## Step-05: 01-filestore-pvc.yaml
```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: gke-filestore-pvc
spec:
  accessModes:
  - ReadWriteMany
  storageClassName: standard-rwx
  resources:
    requests:
      storage: 1Ti
```

## Step-06: 02-write-to-filestore-pod.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: filestore-writer-app
spec:
  containers:
    - name: app
      image: centos
      command: ["/bin/sh"]
      args: ["-c", "while true; do echo GCP File Store used as PV in GKE $(date -u) >> /data/myapp1.txt; sleep 5; done"]
      volumeMounts:
        - name: persistent-storage
          mountPath: /data
  volumes:
    - name: persistent-storage
      persistentVolumeClaim:
        claimName: gke-filestore-pvc
```

## Step-07: 03-myapp1-deployment.yaml
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
          volumeMounts:
            - name: persistent-storage
              mountPath: /usr/share/nginx/html/filestore
      volumes:
        - name: persistent-storage
          persistentVolumeClaim:
            claimName: gke-filestore-pvc              
```

## Step-08: 04-loadBalancer-service.yaml
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

## Step-09: Enable Cloud FileStore API (if not enabled)
- Go to Search -> FileStore -> ENABLE

## Step-09: Deploy kube-manifests
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

## Step-10: Verify GCP Cloud FileStore Instance
- Go to FileStore -> Instances
- Click on **Instance ID: pvc-27cd5c27-0ed0-48d1-bc5f-925adfb8495f**
- **Note:** Instance ID dynamically generated, it can be different in your case starting with pvc-*

## Step-11: Connect to filestore write app Kubernetes pods and Verify
```t
# FileStore write app - Connect to Kubernetes Pod
kubectl exec --stdin --tty <POD-NAME> -- /bin/sh
kubectl exec --stdin --tty filestore-writer-app  -- /bin/sh
cd /data
ls
tail -f myapp1.txt
exit
```

## Step-12: Connect to myapp1 Kubernetes pods and Verify
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

## Step-13: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<EXTERNAL-IP-OF-GET-SERVICE-OUTPUT>/filestore/myapp1.txt
http://35.232.145.61/filestore/myapp1.txt
curl http://35.232.145.61/filestore/myapp1.txt
```


## Step-14: Clean-Up
```t
# Delete Kubernetes Objects
kubectl delete -f kube-manifests/

# Verify if FileStore Instance is deleted
Go to -> FileStore -> Instances
```