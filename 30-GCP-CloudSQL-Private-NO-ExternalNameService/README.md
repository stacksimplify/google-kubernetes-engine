---
title: GKE Storage with GCP Cloud SQL - Without ExternalName Service
description: Use GCP Cloud SQL MySQL DB for GKE Workloads without ExternalName Service
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
- GKE Private Cluster 
- GCP Cloud SQL with Private IP 
- [GKE is a Fully Integrated Network Model](https://cloud.google.com/architecture/gke-compare-network-models)
- GKE is a Fully Integrated Network Model for Kubernetes, that said without ExternalName service we can directly connect to Private or Public IP of Cloud SQL from GKE Cluster itself. 
- We are going to update the UMS Kubernetes Deployment `DB_HOSTNAME` with `Cloud SQL Private IP` and it should work without any issues. 



## Step-02: 03-UserMgmtWebApp-Deployment.yaml
- **Change-1:** Update Cloud SQL IP Address in `command: ['sh', '-c', 'echo -e "Checking for the availability of MySQL Server deployment"; while ! nc -z 10.64.18.3 3306; do sleep 1; printf "-"; done; echo -e "  >> MySQL DB Server has started";']`
- **Change-2:** Update Cloud SQL IP Address for `DB_HOSTNAME` value `value: 10.64.18.3`
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
          #command: ['sh', '-c', 'echo -e "Checking for the availability of MySQL Server deployment"; while ! nc -z mysql-externalname-service 3306; do sleep 1; printf "-"; done; echo -e "  >> MySQL DB Server has started";']      
          command: ['sh', '-c', 'echo -e "Checking for the availability of MySQL Server deployment"; while ! nc -z 10.64.18.3 3306; do sleep 1; printf "-"; done; echo -e "  >> MySQL DB Server has started";']                
      containers:
        - name: usermgmt-webapp
          image: stacksimplify/kube-usermgmt-webapp:1.0.0-MySQLDB
          imagePullPolicy: Always
          ports: 
            - containerPort: 8080           
          env:
            - name: DB_HOSTNAME
              #value: "mysql-externalname-service"            
              value: 10.64.18.3
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


## Step-03: Deploy kube-manifests
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


## Step-04: Access Application
```t
# List Services
kubectl get svc

# Access Application
http://<ExternalIP-from-get-service-output>
Username: admin101
Password: password101
```

## Step-05: Clean-Up
```t
# Delete Kubernetes Objects
kubectl delete -f kube-manifests/

# Delete Cloud SQL MySQL Instance
1. Go to SQL ->  ums-db-private-instance -> DELETE
2. Instance ID: ums-db-private-instance
3. Click on DELETE
```

## References
- [Private Service Access with MySQL](https://cloud.google.com/sql/docs/mysql/configure-private-services-access#console)
- [Private Service Access](https://cloud.google.com/vpc/docs/private-services-access)
- [VPC Network Peering Limits](https://cloud.google.com/vpc/docs/quota#vpc-peering)
- [Configuring Private Service Access](https://cloud.google.com/vpc/docs/configure-private-services-access)
- [Additional Reference Only - Enabling private services access](https://cloud.google.com/service-infrastructure/docs/enabling-private-services-access)

