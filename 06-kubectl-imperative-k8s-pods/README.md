---
title: Kubernetes PODs
description: Learn about Kubernetes Pods
---

## Step-01: PODs Introduction
- What is a POD ?
- What is a Multi-Container POD?

## Step-02: PODs Demo
### Step-02-01: Get Worker Nodes Status
- Verify if kubernetes worker nodes are ready. 
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT-NAME>
gcloud container clusters get-credentials standard-public-cluster-1 --region us-central1 --project kdaida123

# Get Worker Node Status
kubectl get nodes

# Get Worker Node Status with wide option
kubectl get nodes -o wide
```

### Step-02-02:  Create a Pod
- Create a Pod
```t
# Template
kubectl run <desired-pod-name> --image <Container-Image> 

# Replace Pod Name, Container Image
kubectl run my-first-pod --image stacksimplify/kubenginx:1.0.0
```  

### Step-02-03: List Pods
- Get the list of pods
```t
# List Pods
kubectl get pods

# Alias name for pods is po
kubectl get po
```

### Step-02-04: List Pods with wide option
- List pods with wide option which also provide Node information on which Pod is running
```t
# List Pods with Wide Option
kubectl get pods -o wide
```

### Step-02-05: What happened in the backgroup when above command is run?
1. Kubernetes created a pod
2. Pulled the docker image from docker hub
3. Created the container in the pod
4. Started the container present in the pod

### Step-02-06: Describe Pod
- Describe the POD, primarily required during troubleshooting. 
- Events shown will be of a great help during troubleshooting. 
```t
# To get list of pod names
kubectl get pods

# Describe the Pod
kubectl describe pod <Pod-Name>
kubectl describe pod my-first-pod 
Observation:
1. Review Events - thats the key for troubleshooting, understanding what happened
```

### Step-02-07: Access Application
- Currently we can access this application only inside worker nodes. 
- To access it externally, we need to create a **NodePort or Load Balancer Service**. 
- **Services** is one very very important concept in Kubernetes. 

### Step-02-08: Delete Pod
```t
# To get list of pod names
kubectl get pods

# Delete Pod
kubectl delete pod <Pod-Name>
kubectl delete pod my-first-pod
```

## Step-03: Load Balancer Service Introduction
- What are Services in k8s?
- What is a Load Balancer Service?
- How it works?

## Step-04: Demo - Expose Pod with a Service
- Expose pod with a service (Load Balancer Service) to access the application externally (from internet)
- **Ports**
  - **port:** Port on which node port service listens in Kubernetes cluster internally
  - **targetPort:** We define container port here on which our application is running.
- Verify the following before LB Service creation
  - Azure Standard Load Balancer created for Azure AKS Cluster
    - Frontend IP Configuration
    - Load Balancing Rules
  - Azure Public IP 
```t
# Create  a Pod
kubectl run <desired-pod-name> --image <Container-Image> 
kubectl run my-first-pod --image stacksimplify/kubenginx:1.0.0 

# Expose Pod as a Service
kubectl expose pod <Pod-Name>  --type=LoadBalancer --port=80 --name=<Service-Name>
kubectl expose pod my-first-pod  --type=LoadBalancer --port=80 --name=my-first-service

# Get Service Info
kubectl get service
kubectl get svc
Observation:
1. Initially External-IP will show as pending and slowly it will get the external-ip assigned and displayed.
2. It will take 2 to 3 minutes to get the external-ip listed

# Describe Service
kubectl describe service my-first-service

# Access Application
http://<External-IP-from-get-service-output>
curl http://<External-IP-from-get-service-output>
```
- Verify the following after LB Service creation
- Google Load Balancer created, verify it. 
  - Verify Backends 
  - Verify Frontends
- Verify **Workloads and Services** on Google GKE Dashboard GCP Console


## Step-05: Interact with a Pod
### Step-05-01: Verify Pod Logs
```t
# Get Pod Name
kubectl get po

# Dump Pod logs
kubectl logs <pod-name>
kubectl logs my-first-pod

# Stream pod logs with -f option and access application to see logs
kubectl logs <pod-name>
kubectl logs -f my-first-pod
```
- **Important Notes**
- Refer below link and search for **Interacting with running Pods** for additional log options
- Troubleshooting skills are very important. So please go through all logging options available and master them.
- **Reference:** https://kubernetes.io/docs/reference/kubectl/cheatsheet/

### Step-05-02: Connect to a Container in POD and execute command
```t
# Connect to Nginx Container in a POD
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec -it my-first-pod -- /bin/bash

# Execute some commands in Nginx container
ls
cd /usr/share/nginx/html
cat index.html
exit
```
### Step-05-03: Running individual commands in a Container
```t
# Template
kubectl exec -it <pod-name> -- <COMMAND>

# Sample Commands
kubectl exec -it my-first-pod -- env
kubectl exec -it my-first-pod -- ls
kubectl exec -it my-first-pod -- cat /usr/share/nginx/html/index.html
```

## Step-06: Get YAML Output of Pod & Service
### Get YAML Output
```t
# Get pod definition YAML output
kubectl get pod my-first-pod -o yaml   

# Get service definition YAML output
kubectl get service my-first-service -o yaml   
```

## Step-07: Clean-Up
```t
# Get all Objects in default namespace
kubectl get all

# Delete Services
kubectl delete svc my-first-service

# Delete Pod
kubectl delete pod my-first-pod

# Get all Objects in default namespace
kubectl get all
```


## LOGS - More Options

```t
# Return snapshot logs from pod nginx with only one container
kubectl logs nginx

# Return snapshot of previous terminated ruby container logs from pod web-1
kubectl logs -p -c ruby web-1

# Begin streaming the logs of the ruby container in pod web-1
kubectl logs -f -c ruby web-1

# Display only the most recent 20 lines of output in pod nginx
kubectl logs --tail=20 nginx

# Show all logs from pod nginx written in the last hour
kubectl logs --since=1h nginx
```
