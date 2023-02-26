---
title: GCP Google Kubernetes Engine GKE Ingress Custom Health Checks
description: Implement GCP Google Kubernetes Engine GKE Ingress Custom Health Checks
---

## Step-00: Pre-requisites
1. Verify if GKE Cluster is created
2. Verify if kubeconfig for kubectl is configured in your local terminal
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>

# Replace Values CLUSTER-NAME, REGION, PROJECT
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123

# List Kubernetes Nodes
kubectl get nodes
```

3. ExternalDNS Controller should be installed and ready to use
```t
# List Namespaces (external-dns-ns namespace should be present)
kubectl get ns

# List External DNS Pods
kubectl -n external-dns-ns get pods
```

## Step-01: Introduction
1. Implement Self Signed SSL Certificates with GKE Ingress Service
2. Create SSL Certificates using OpenSSL.
3. Create Kubernetes Secret with SSL Certificate and Private Key
4. Reference these Kubernetes Secrets in Ingress Service **Ingress spec.tls**

## Step-02: App1 - Create Self-Signed SSL Certificates and Kubernetes Secrets
```t
# Change Directory 
cd SSL-SelfSigned-Certs

# Create your app1 key:
openssl genrsa -out app1-ingress.key 2048

# Create your app1 certificate signing request:
openssl req -new -key app1-ingress.key -out app1-ingress.csr -subj "/CN=app1.kalyanreddydaida.com"

# Create your app1 certificate:
openssl x509 -req -days 7300 -in app1-ingress.csr -signkey app1-ingress.key -out app1-ingress.crt

# Create a Secret that holds your app1 certificate and key:
kubectl create secret tls app1-secret  --cert app1-ingress.crt --key app1-ingress.key

# List Secrets
kubectl get secrets
```


## Step-03: App2 - Create Self-Signed SSL Certificates and Kubernetes Secrets
```t
# Change Directory 
cd SSL-SelfSigned-Certs

# Create your app2 key:
openssl genrsa -out app2-ingress.key 2048

# Create your app2 certificate signing request:
openssl req -new -key app2-ingress.key -out app2-ingress.csr -subj "/CN=app2.kalyanreddydaida.com"

# Create your app2 certificate:
openssl x509 -req -days 7300 -in app2-ingress.csr -signkey app2-ingress.key -out app2-ingress.crt

# Create a Secret that holds your app2 certificate and key:
kubectl create secret tls app2-secret  --cert app2-ingress.crt --key app2-ingress.key

# List Secrets
kubectl get secrets
```

## Step-03: App3 - Create Self-Signed SSL Certificates and Kubernetes Secrets
```t
# Change Directory 
cd SSL-SelfSigned-Certs

# Create your app3 key:
openssl genrsa -out app3-ingress.key 2048

# Create your app3 certificate signing request:
openssl req -new -key app3-ingress.key -out app3-ingress.csr -subj "/CN=app3-default.kalyanreddydaida.com"

# Create your app3 certificate:
openssl x509 -req -days 7300 -in app3-ingress.csr -signkey app3-ingress.key -out app3-ingress.crt

# Create a Secret that holds your app3 certificate and key:
kubectl create secret tls app3-secret  --cert app3-ingress.crt --key app3-ingress.key

# List Secrets
kubectl get secrets
```

## Step-04: No changes to following kube-manifests from previous Ingress Name Based Virtual Host Routing Demo
1. 01-Nginx-App1-Deployment-and-NodePortService.yaml
2. 02-Nginx-App2-Deployment-and-NodePortService.yaml
3. 03-Nginx-App3-Deployment-and-NodePortService.yaml
4. 05-frontendconfig.yaml

## Step-05: Review 04-ingress-self-signed-ssl.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-selfsigned-ssl
  annotations:
    # External Load Balancer
    kubernetes.io/ingress.class: "gce"  
    # Static IP for Ingress Service
    kubernetes.io/ingress.global-static-ip-name: "gke-ingress-extip1"   
    # SSL Redirect HTTP to HTTPS
    networking.gke.io/v1beta1.FrontendConfig: "my-frontend-config"   
    # External DNS - For creating a Record Set in Google Cloud Cloud DNS
    external-dns.alpha.kubernetes.io/hostname: app3-default.kalyanreddydaida.com
spec: 
  # SSL Certs - Associate using Kubernetes Secrets         
  tls:
  - secretName: app1-secret
  - secretName: app2-secret
  - secretName: app3-secret
  defaultBackend:
    service:
      name: app3-nginx-nodeport-service
      port:
        number: 80           
  rules:
    - host: app1.kalyanreddydaida.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app1-nginx-nodeport-service
                port: 
                  number: 80
    - host: app2.kalyanreddydaida.com
      http:
        paths:                  
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app2-nginx-nodeport-service
                port: 
                  number: 80
```

## Step-06: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests

# List Deployments
kubectl get deploy

# List Pods
kubectl get pods

# List Services
kubectl get svc

# List Ingress Services
kubectl get ingress

# Describe Ingress Service
kubectl describe ingress ingress-selfsigned-ssl

# Verify external-dns Controller logs
kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
[or]
kubectl -n external-dns-ns get pods
kubectl -n external-dns-ns logs -f <External-DNS-Pod-Name>

# Verify Cloud DNS
1. Go to Network Services -> Cloud DNS -> kalyanreddydaida-com
2. Verify Record sets, DNS Name we added in Ingress Service should be present 

# List FrontendConfigs
kubectl get frontendconfig

# Verify SSL Certificates
Go to Load Balancers
1. Load Balancers View -> In Frontends
2. Load Balancers Components View -> Certificates Tab
```

## Step-07: Access Application
```t
# Access Application
http://app1.kalyanreddydaida.com/app1/index.html
http://app2.kalyanreddydaida.com/app2/index.html
http://app3-default.kalyanreddydaida.com

Observation:
1. All 3 URLS should work as expected. In your case, replace YOUR_DOMAIN name for testing
2. HTTP to HTTPS redirect should work
3. You will get a warning "The certificate is not trusted because it is self-signed.". Click on "Accept the risk and continue"
```


## Step-08: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests

# List Kubernetes Secrets
kubectl get secrets

# Delete Kubernetes Secrets
kubectl delete secret app1-secret 
kubectl delete secret app2-secret 
kubectl delete secret app3-secret 
```

## References
- [User Managed Certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-multi-ssl#user-managed-certs)
