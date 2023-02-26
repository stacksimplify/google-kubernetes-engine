---
title: GCP Google Kubernetes Engine GKE Ingress with External IP
description: Implement GCP Google Kubernetes Engine GKE Ingress with External IP
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

3. Registered Domain using Google Cloud Domains

## Step-01: Introduction
- Reserve an External IP Address
- Using Annotaiton `kubernetes.io/ingress.global-static-ip-name` associate this External IP to Ingress Service

## Step-02: Create External IP Address using gcloud
```t
# Create External IP Address
gcloud compute addresses create ADDRESS_NAME --global
gcloud compute addresses create gke-ingress-extip1 --global

# Describe External IP Address 
gcloud compute addresses describe ADDRESS_NAME --global
gcloud compute addresses describe gke-ingress-extip1 --global

# List External IP Address
gcloud compute addresses list

# Verify
Go to VPC Network -> IP Addresses -> External IP Address
```

## Step-03: Add RECORDSET Google Cloud DNS for this External IP
- Go to Network Services -> Cloud DNS -> kalyanreddydaida.com -> **ADD RECORD SET**
- DNS NAME: demo1.kalyanreddydaida.com
- **IPv4 Address:** <EXTERNAL-IP-RESERVERD-IN-STEP-02>
- Click on **CREATE**

## Step-04: Verify DNS resolving to IP 
```t
# nslookup test
nslookup demo1.kalyanreddydaida.com

## Sample Output
Kalyans-Mac-mini:google-kubernetes-engine kalyanreddy$ nslookup demo1.kalyanreddydaida.com
Server:		192.168.2.1
Address:	192.168.2.1#53

Non-authoritative answer:
Name:	demo1.kalyanreddydaida.com
Address: 34.120.32.120

Kalyans-Mac-mini:google-kubernetes-engine kalyanreddy$ 
```


## Step-05: 04-Ingress-external-ip.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-external-ip
  annotations:
    # External Load Balancer
    kubernetes.io/ingress.class: "gce"  
    # Static IP for Ingress Service
    kubernetes.io/ingress.global-static-ip-name: "gke-ingress-extip1"   
spec: 
  defaultBackend:
    service:
      name: app3-nginx-nodeport-service
      port:
        number: 80                            
  rules:
    - http:
        paths:           
          - path: /app1
            pathType: Prefix
            backend:
              service:
                name: app1-nginx-nodeport-service
                port: 
                  number: 80
          - path: /app2
            pathType: Prefix
            backend:
              service:
                name: app2-nginx-nodeport-service
                port: 
                  number: 80          
```

## Step-06: No changes to other 3 YAML Files
- 01-Nginx-App1-Deployment-and-NodePortService.yaml
- 02-Nginx-App2-Deployment-and-NodePortService.yaml
- 03-Nginx-App3-Deployment-and-NodePortService.yaml

## Step-07: Deploy kube-manifests and verify
```t
# Deploy Kubernetes manifests
kubectl apply -f kube-manifests

# List Pods
kubectl get pods

# List Services
kubectl get svc

# List Ingress Load Balancers
kubectl get ingress

# Describe Ingress and view Rules
kubectl describe ingress ingress-external-ip
```



## Step-08: Access Application
```t
# Important Note
Wait for 2 to 3 minutes for the Load Balancer to completely create and ready for use else we will get HTTP 502 errors

# Access Application
http://<DNS-DOMAIN-NAME>/app1/index.html
http://<DNS-DOMAIN-NAME>/app2/index.html
http://<DNS-DOMAIN-NAME>/

# Replace Domain Name registered in Cloud DNS
http://demo1.kalyanreddydaida.com/app1/index.html
http://demo1.kalyanreddydaida.com/app2/index.html
http://demo1.kalyanreddydaida.com/
```

## Step-09: Clean Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests

# Verify Load Balancer Deleted
Go to Network Services -> Load Balancing -> No Load balancers should be present
```

