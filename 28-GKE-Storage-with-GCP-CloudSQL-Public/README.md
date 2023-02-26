---
title: GKE Storage with GCP Cloud SQL - MySQL Public Instance
description: Use GCP Cloud SQL MySQL DB for GKE Workloads
---

## Step-00: Pre-requisites
1. Verify if GKE Cluster is created
2. Verify if kubeconfig for kubectl is configured in your local terminal
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --zone <ZONE> --project <PROJECT>

# Replace Values CLUSTER-NAME, ZONE, PROJECT
gcloud container clusters get-credentials standard-cluster-1 --zone us-central1-c --project kdaida123
```

## Step-01: Introduction
- GKE Private Cluster 
- GCP Cloud SQL with Public IP and Authorized Network for DB as entire internet (0.0.0.0/0)

## Step-02: Create Google Cloud SQL MySQL Instance
- Go to SQL -> Choose MySQL
- **Instance ID:** ums-db-public-instance
- **Password:** KalyanReddy13
- **Database Version:** MYSQL 8.0
- **Choose a configuration to start with:** Development
- **Choose region and zonal availability**
  - **Region:** US-central1(IOWA)
  - **Zonal availability:** Single Zone
  - **Primary Zone:** us-central1-a
- **Customize your instance**
- **Machine Type**
  - **Machine Type:** LightWeight (1 vCPU, 3.75GB)
- **STORAGE**  
  - **Storage Type:** HDD
  - **Storage Capacity:** 10GB 
  - **Enable automatic storage increases:** CHECKED
- **CONNECTIONS**  
  - **Instance IP Assignment:** 
    - **Private IP:** UNCHECKED
    - **Public IP:** CHECKED
  - **Authorized networks**
    - **Name:** All-Internet
    - **Network:**  0.0.0.0/0     
    - Click on **DONE**
- **DATA PROTECTION**
  - **Automatic Backups:** UNCHECKED
  - **Enable Deletion protection:** UNCHECKED
- **Maintenance:** Leave to defaults
- **Flags:** Leave to defaults
- **Labels:** Leave to defaults
- Click on **CREATE INSTANCE**      

## Step-03: Perform Telnet Test from local desktop
```t
# Telnet Test
telnet <MYSQL-DB-PUBLIC-IP> 3306

# Replace Public IP
telnet 35.184.228.151 3306

## SAMPLE OUTPUT
Kalyans-Mac-mini:25-GKE-Storage-with-GCP-Cloud-SQL kalyanreddy$ telnet 35.184.228.151 3306
Trying 35.184.228.151...
Connected to 151.228.184.35.bc.googleusercontent.com.
Escape character is '^]'.
Q
8.0.26-google?h'Sxcr+?nd'h<a(X`z=mysql_native_password2#08S01Got timeout reading communication packetsConnection closed by foreign host.
Kalyans-Mac-mini:25-GKE-Storage-with-GCP-Cloud-SQL kalyanreddy$
```


## Step-04: Create DB Schema webappdb 
- Go to SQL ->  ums-db-public-instance -> Databases -> **CREATE DATABASE**
- **Database Name:** webappdb
- **Character set:** utf8
- **Collation:** Default collation
- Click on **CREATE**


## Step-05: 01-MySQL-externalName-Service.yaml
- Update Cloud SQL MySQL DB `Public IP` in ExternalName Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-externalname-service
spec:
  type: ExternalName
  externalName: 35.184.228.151
```

## Step-06: 02-Kubernetes-Secrets.yaml
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mysql-db-password
type: Opaque
data: 
  db-password: S2FseWFuUmVkZHkxMw==

# Base64 of KalyanReddy13
# https://www.base64encode.org/
# Base64 of KalyanReddy13 is S2FseWFuUmVkZHkxMw==
```

## Step-07: 03-UserMgmtWebApp-Deployment.yaml
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
          command: ['sh', '-c', 'echo -e "Checking for the availability of MySQL Server deployment"; while ! nc -z mysql-externalname-service 3306; do sleep 1; printf "-"; done; echo -e "  >> MySQL DB Server has started";']      
      containers:
        - name: usermgmt-webapp
          image: stacksimplify/kube-usermgmt-webapp:1.0.0-MySQLDB
          imagePullPolicy: Always
          ports: 
            - containerPort: 8080           
          env:
            - name: DB_HOSTNAME
              value: "mysql-externalname-service"            
            - name: DB_PORT
              value: "3306"            
            - name: DB_NAME
              value: "webappdb"            
            - name: DB_USERNAME
              value: "root"            
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql-db-password
                  key: db-password   
```

## Step-08: 04-UserMgmtWebApp-LoadBalancer-Service.yaml
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


## Step-10: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<ExternalIP-from-get-service-output>
Username: admin101
Password: password101
```

## Step-11: Connect to MySQL DB (Cloud SQL) from GKE Cluster using kubectl
```t
## Verify from Kubernetes Cluster, we are able to connect to MySQL DB
# Template
kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h <Kubernetes-ExternalName-Service> -u <USER_NAME> -p<PASSWORD>

# MySQL Client 8.0: Replace External Name Service, Username and Password
kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h mysql-externalname-service -u root -pKalyanReddy13

mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;
mysql> exit
```

## Step-12: Create New user admin102 and verify in Cloud SQL MySQL webappdb
```t
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

# MySQL Client 8.0: Replace External Name Service, Username and Password
kubectl run -it --rm --image=mysql:8.0 --restart=Never mysql-client -- mysql -h mysql-externalname-service -u root -pKalyanReddy13

mysql> show schemas;
mysql> use webappdb;
mysql> show tables;
mysql> select * from user;
mysql> exit
```

## Step-13: Clean-Up
```t
# Delete Kubernetes Objects
kubectl delete -f kube-manifests/

# Delete Cloud SQL MySQL Instance
1. Go to SQL ->  ums-db-public-instance -> DELETE
2. Instance ID: ums-db-public-instance
3. Click on DELETE
```
