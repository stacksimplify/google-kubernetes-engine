---
title: Kubernetes ReplicaSets with YAML
description: Learn to write and test Kubernetes ReplicaSets with YAML
---

## Step-01: Create ReplicaSet Definition
- **01-replicaset-definition.yml**
```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: myapp2-rs
spec:
  replicas: 3 # 3 Pods should exist at all times.
  selector:  # Pods label should be defined in ReplicaSet label selector
    matchLabels:
      app: myapp2
  template:
    metadata:
      name: myapp2-pod
      labels:
        app: myapp2 # Atleast 1 Pod label should match with ReplicaSet Label Selector
    spec:
      containers:
      - name: myapp2
        image: stacksimplify/kubenginx:2.0.0
        ports:
          - containerPort: 80
```
## Step-02: Create ReplicaSet
- Create ReplicaSet with 3 Replicas
```t
# Create ReplicaSet
kubectl apply -f 01-replicaset-definition.yml

# List Replicasets
kubectl get rs
```
- Delete a pod
- ReplicaSet immediately creates the pod. 
```t
# List Pods
kubectl get pods

# Delete Pod
kubectl delete pod <Pod-Name>
```

## Step-03: Create LoadBalancer Service for ReplicaSet
```yaml
apiVersion: v1
kind: Service
metadata:
  name: replicaset-loadbalancer-service
spec:
  type: LoadBalancer 
  selector: 
    app: myapp2 
  ports: 
    - name: http
      port: 80
      targetPort: 80
     
```
- **Create LoadBalancer Service for ReplicaSet & Test**
```t
# Create LoadBalancer Service
kubectl apply -f 02-replicaset-LoadBalancer-servie.yml

# List LoadBalancer Service
kubectl get svc

# Access Application
http://<Load-Balancer-Service-IP>
```


## Step-04: Clean-Up Kubernetes ReplicaSet and Service
```t
# Change Directory
cd kube-manifests

# Delete Pod
kubectl delete -f 01-replicaset-definition.yml

# Delete Service
kubectl delete -f  02-replicaset-LoadBalancer-servie.yml
```


## API References
- [ReplicaSet](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.19/#replicaset-v1-apps)