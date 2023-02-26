---
title: Kubernetes Services with YAML
description: Learn to write and test Kubernetes Services with YAML
---

## Step-01: Introduction to Services
- We are going to look in to below two services in detail with a frotnend and backend example
  - LoadBalancer Service
  - ClusterIP Service

## Step-02: Create Backend Deployment & Cluster IP Service
- Write the Deployment template for backend REST application.
- Write the Cluster IP service template for backend REST application.
- **Important Notes:** 
  - Name of Cluster IP service should be `name: my-backend-service` because  same is configured in frontend nginx reverse proxy `default.conf`. 
  - Test with different name and understand the issue we face
  - We have also discussed about in our  [Section-12](https://github.com/stacksimplify/google-kubernetes-engine/tree/main/12-kubectl-imperative-k8s-services)
```t
# Change Directory
cd kube-manifests

# Deploy Backend Kubernetes Deployment and ClusterIP Service 
kubectl get all
kubectl apply -f 01-backend-deployment.yml -f 02-backend-clusterip-service.yml
kubectl get all
```


## Step-03: Create Frontend Deployment & LoadBalancer Service
- Write the Deployment template for frontend Nginx Application
- Write the LoadBalancer service template for frontend Nginx Application
```t
# Change Directory
cd kube-manifests

# Deploy Frontend Kubernetes Deployment and LoadBalancer Service 
kubectl get all
kubectl apply -f 03-frontend-deployment.yml -f 04-frontend-LoadBalancer-service.yml
kubectl get all
```
- **Access REST Application**
```t
# Get Service IP
kubectl get svc

# Access REST Application 
http://<Load-Balancer-Service-IP>/hello
curl http://<Load-Balancer-Service-IP>/hello
```

## Step-04: Delete & Recreate Objects using kubectl apply
### Delete Objects (file by file)
```t
# Change Directory 
cd kube-manifests/

# Delete Objects File by file
kubectl delete -f 01-backend-deployment.yml -f 02-backend-clusterip-service.yml -f 03-frontend-deployment.yml -f 04-frontend-LoadBalancer-service.yml
kubectl get all
```
### Recreate Objects using YAML files in a folder
```t
# Change Directory 
cd 17-yaml-declarative-k8s-services/

# Recreate Objects by referencing a folder
kubectl apply -f kube-manifests/
kubectl get all
```

### Delete Objects using YAML files in folder
```t
# Change Directory 
cd 17-yaml-declarative-k8s-services/

# Delete Objects by just referencing a folder
kubectl delete -f kube-manifests/
kubectl get all
```


## Additional References - Use Label Selectors for get and delete
- [Labels](https://kubernetes.io/docs/concepts/cluster-administration/manage-deployment/#using-labels-effectively)
- [Labels-Selectors](https://kubernetes.io/docs/concepts/overview/working-with-objects/labels/#label-selectors)