---
title: GCP Google Kubernetes Engine GKE Service with External DNS 
description: Implement GCP Google Kubernetes Engine GKE Service with External DNS
---
## Step-00: Pre-requisites
1. Verify if GKE Cluster is created
2. Verify if kubeconfig for kubectl is configured in your local terminal
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>

# Replace Values CLUSTER-NAME, REGION, PROJECT
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123
```
3. External DNS Controller Installed

## Step-01: Introduction
- Kubernetes Service of Type Load Balancer with External DNS
- We are going to use the Annotation `external-dns.alpha.kubernetes.io/hostname` in Kubernetes Service.
- DNS Recordsets will be automatically added to Google Cloud DNS using external-dns controller when Ingress Service deployed

## Step-02: 01-kubernetes-deployment.yaml
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
```

## Step-03: 02-kubernetes-loadbalancer-service.yaml
```yaml
apiVersion: v1
kind: Service 
metadata:
  name: myapp1-lb-service
  annotations:
    # External DNS - For creating a Record Set in Google Cloud Cloud DNS
    external-dns.alpha.kubernetes.io/hostname: extdns-k8s-svc-demo.kalyanreddydaida.com
spec:
  type: LoadBalancer # ClusterIp, # NodePort
  selector:
    app: myapp1
  ports: 
    - name: http
      port: 80 # Service Port
      targetPort: 80 # Container Port
```

## Step-05: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests

# List Deployments
kubectl get deploy 

# List Pods
kubectl get pods

# List Services
kubectl get svc

# Verify external-dns Controller logs
kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
[or]
kubectl -n external-dns-ns get pods
kubectl -n external-dns-ns logs -f <External-DNS-Pod-Name>

# Verify Cloud DNS
1. Go to Network Services -> Cloud DNS -> kalyanreddydaida-com
2. Verify Record sets, DNS Name we added in Kubernetes Service should be present 

# Access Application
http://<DNS-Name>
http://extdns-k8s-svc-demo.kalyanreddydaida.com
```


## Step-06: Delete kube-manifests
```t
# Delete Kubernetes Objects
kubectl delete -f kube-manifests/

# Verify external-dns Controller logs
kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
[or]
kubectl -n external-dns-ns get pods
kubectl -n external-dns-ns logs -f <External-DNS-Pod-Name>


# Verify Cloud DNS
1. Go to Network Services -> Cloud DNS -> kalyanreddydaida-com
2. Verify Record sets, DNS Name we added in Kubernetes Service should be not preset (already deleted) 
```
