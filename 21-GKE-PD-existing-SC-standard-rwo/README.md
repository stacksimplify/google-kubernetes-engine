---
title: GKE Persistent Disks Existing StorageClass standard-rwo
description: Use existing storageclass standard-rwo in Kubernetes Workloads
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

- Use predefined Storage Class `standard-rwo`
- `standard-rwo` uses balanced persistent disk

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
  storageClassName: standard-rwo
  resources: 
    requests:
      storage: 4Gi

# NEED FOR PVC
# 1. Dynamic volume provisioning allows storage volumes to be created 
# on-demand. 

# 2. Without dynamic provisioning, cluster administrators have to manually 
# make calls to their cloud or storage provider to create new storage 
# volumes, and then create PersistentVolume objects to represent them in k8s

# 3. The dynamic provisioning feature eliminates the need for cluster 
# administrators to pre-provision storage. Instead, it automatically 
# provisions storage when it is requested by users.

# 4. PVC: Users request dynamically provisioned storage by including 
# a storage class in their PersistentVolumeClaim
```

## Step-04: 02-UserManagement-ConfigMap.yaml
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: usermanagement-dbcreation-script
data: 
  mysql_usermgmt.sql: |-
    DROP DATABASE IF EXISTS webappdb;
    CREATE DATABASE webappdb; 
```

## Step-05: 03-mysql-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec: 
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  strategy:
    type: Recreate # terminates all the pods and replaces them with the new version.
  template: 
    metadata: 
      labels: 
        app: mysql
    spec: 
      containers:
        - name: mysql
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
            claimName: mysql-pv-claim
        - name: usermanagement-dbcreation-script
          configMap:
            name: usermanagement-dbcreation-script


# VERY IMPORTANT POINTS ABOUT CONTAINERS AND POD VOLUMES: 
## 1. On-disk files in a container are ephemeral
## 2. One problem is the loss of files when a container crashes. 
## 3. Kubernetes Volumes solves above two as these volumes are configured to POD and not container. 
## Only they can be mounted in Container
## 4. Using Compute Enginer Persistent Disk CSI Driver is a super generalized approach 
## for having Persistent Volumes for workloads in Kubernetes


## ENVIRONMENT VARIABLES
# 1. When you create a Pod, you can set environment variables for the 
# containers that run in the Pod. 
# 2. To set environment variables, include the env or envFrom field in 
# the configuration file.


## DEPLOYMENT STRATEGIES
# 1. Rolling deployment: This strategy  replaces pods running the old version of the application with the new version, one by one, without downtime to the cluster.
# 2. Recreate: This strategy terminates all the pods and replaces them with the new version.
# 3. Ramped slow rollout: This strategy  rolls out replicas of the new version, while in parallel, shutting down old replicas. 
# 4. Best-effort controlled rollout: This strategy  specifies a “max unavailable” parameter which indicates what percentage of existing pods can be unavailable during the upgrade, enabling the rollout to happen much more quickly.
# 5. Canary Deployment: This strategy  uses a progressive delivery approach, with one version of the application serving maximum users, and another, newer version serving a small set of test users. The test deployment is rolled out to more users if it is successful.
```

## Step-06: 04-mysql-clusterip-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata: 
  name: mysql
spec:
  selector:
    app: mysql 
  ports: 
    - port: 3306  
  clusterIP: None # This means we are going to use Pod IP    
```
## Step-07: 05-UserMgmtWebApp-Deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment 
metadata:
  name: usermgmt-webapp
  labels:
    app: usermgmt-webapp
spec:
  replicas: 1
  selector:
    matchLabels:
      app: usermgmt-webapp
  template:  
    metadata:
      labels: 
        app: usermgmt-webapp
    spec:
      initContainers:
        - name: init-db
          image: busybox:1.31
          command: ['sh', '-c', 'echo -e "Checking for the availability of MySQL Server deployment"; while ! nc -z mysql 3306; do sleep 1; printf "-"; done; echo -e "  >> MySQL DB Server has started";']      
      containers:
        - name: usermgmt-webapp
          image: stacksimplify/kube-usermgmt-webapp:1.0.0-MySQLDB
          imagePullPolicy: Always
          ports: 
            - containerPort: 8080           
          env:
            - name: DB_HOSTNAME
              value: "mysql"            
            - name: DB_PORT
              value: "3306"            
            - name: DB_NAME
              value: "webappdb"            
            - name: DB_USERNAME
              value: "root"            
            - name: DB_PASSWORD
              value: "dbpassword11"            
```
## Step-08: 06-UserMgmtWebApp-LoadBalancer-Service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: usermgmt-webapp-lb-service
  labels: 
    app: usermgmt-webapp
spec: 
  type: LoadBalancer
  selector: 
    app: usermgmt-webapp
  ports: 
    - port: 80 # Service Port
      targetPort: 8080 # Container Port
```
## Step-09: Deploy kube-manifests
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

# Sample Message for Successful Start of JVM
2022-06-20 09:34:32.519  INFO 1 --- [ost-startStop-1] .r.SpringbootSecurityInternalApplication : Started SpringbootSecurityInternalApplication in 14.891 seconds (JVM running for 23.283)
20-Jun-2022 09:34:32.593 INFO [localhost-startStop-1] org.apache.catalina.startup.HostConfig.deployWAR Deployment of web application archive /usr/local/tomcat/webapps/ROOT.war has finished in 21,016 ms
20-Jun-2022 09:34:32.623 INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["http-apr-8080"]
20-Jun-2022 09:34:32.688 INFO [main] org.apache.coyote.AbstractProtocol.start Starting ProtocolHandler ["ajp-apr-8009"]
20-Jun-2022 09:34:32.713 INFO [main] org.apache.catalina.startup.Catalina.start Server startup in 21275 ms
```

## Step-10: Verify Persistent Disks
- Go to Compute Engine -> Storage -> Disks
- Search for `4GB` Persistent Disk

## Step-11: Verify Kubernetes Workloads, Services ConfigMaps on Kubernetes Engine Dashboard
```t
# Verify Workloads
Go to Kubernetes Engine -> Workloads
Observation:
1. You should see "mysql" and "usermgmt-webapp" deployments

# Verify Services
Go to Kubernetes Engine -> Services & Ingress
Observation:
1. You should "mysql ClusterIP Service" and "usermgmt-webapp-lb-service"

# Verify ConfigMaps
Go to Kubernetes Engine -> Secrets & ConfigMaps
Observation: 
1. You should find the ConfigMap "usermanagement-dbcreation-script"

# Verify Persistent Volume Claim
Go to Kubernetes Engine -> Storage -> PERSISTENT VOLUME CLAIMS TAB
Observation: 
1. You should see PVC "mysql-pv-claim"

# Verify StorageClass
Go to Kubernetes Engine -> Storage -> STORAGE CLASSES TAB
Observation: 
1. You should see 3 Storage Classes out of which "standard-rwo" and "premium-rwo" are part of Compute Engine Persistent Disks (latest and greatest - Recommended for use)
2. Not recommended to use Storage Class with name "standard" (Older version)
```
## Step-13: Connect to MySQL Database
```t
# Template: Connect to MySQL Database using kubectl
kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h <Kubernetes-ClusterIP-Service> -u <USER_NAME> -p<PASSWORD>

# MySQL Client 8.0: Replace ClusterIP Service, Username and Password
kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h mysql -u root -pdbpassword11

mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;
mysql> exit
```


## Step-12: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<ExternalIP-from-get-service-output>
Username: admin101
Password: password101

# Create New User
Username: admin102
Password: password102
First Name: fname102
Last Name: lname102
Email Address: admin102@stacksimplify.com
Social Security Address: ssn102

# Verify this user in MySQL DB
# Template: Connect to MySQL Database using kubectl
kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h <Kubernetes-ClusterIP-Service> -u <USER_NAME> -p<PASSWORD>

# MySQL Client 8.0: Replace ClusterIP Service, Username and Password
kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h mysql -u root -pdbpassword11

mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;
mysql> select * from user;
Observation:
1. You should find the newly created user from browser successfully created in MySQL DB.
2. In simple terms, we have done the following
a. Created MySQL k8s Deployment in GKE CLuster
b. Created Java WebApplication  k8s Deployment in GKE Cluster
c. Accessed Application using GKE Load Balancer IP using browser
d. Created a new user in this application and that user successfully stored in MySQL DB.
e. END TO END FLOW from Browser to DB using GKE Cluster we have seen.
```

## Step-13: Verify GCE PD CSI Driver Logging
- https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver
```t
# Cloud Logging Query 
 resource.type="k8s_container"
 resource.labels.project_id="PROJECT_ID"
  resource.labels.cluster_name="CLUSTER_NAME"
 resource.labels.namespace_name="kube-system"
 resource.labels.container_name="gce-pd-driver"

# Cloud Logging Query (Replace Values)
 resource.type="k8s_container"
 resource.labels.project_id="kdaida123"
 resource.labels.cluster_name="standard-cluster-private-1"
 resource.labels.namespace_name="kube-system"
 resource.labels.container_name="gce-pd-driver"
```

## Step-14: Clean-Up
```t
# Delete kube-manifests
kubectl delete -f kube-manifests/
```

## Reference
- [Using the Compute Engine persistent disk CSI Driver](https://cloud.google.com/kubernetes-engine/docs/how-to/persistent-volumes/gce-pd-csi-driver)


## Addtional-Data-01
1. It enables the automatic deployment and management of the persistent disk driver without having to manually set it up.
2. You can use customer-managed encryption keys (CMEKs). These keys are used to encrypt the data encryption keys that encrypt your data. 
3. You can use volume snapshots with the Compute Engine persistent disk CSI Driver. Volume snapshots let you create a copy of your volume at a specific point in time. You can use this copy to bring a volume back to a prior state or to provision a new volume.
4. Bug fixes and feature updates are rolled out independently from minor Kubernetes releases. This release schedule typically results in a faster release cadence.

## Addtional-Data-02
- For Standard Clusters: The Compute Engine persistent disk CSI Driver is enabled by default on newly created clusters 
  - Linux clusters: GKE version 1.18.10-gke.2100 or later, or 1.19.3-gke.2100 or later.
  - Windows clusters: GKE version 1.22.6-gke.300 or later, or 1.23.2-gke.300 or later.
- For Autopilot clusters: The Compute Engine persistent disk CSI Driver is enabled by default and cannot be disabled or edited.

## Addtional-Data-03
- GKE automatically installs the following StorageClasses:
  - standard-rwo:  using balanced persistent disk
  - premium-rwo: using SSD persistent disk
- For Autopilot clusters: The default StorageClass is standard-rwo, which uses the Compute Engine persistent disk CSI Driver. 
- For Standard clusters: The default StorageClass uses the Kubernetes in-tree gcePersistentDisk volume plugin.
```t
# You can find the name of your installed StorageClasses by running the following command:
kubectl get sc
or
kubectl get storageclass
```
