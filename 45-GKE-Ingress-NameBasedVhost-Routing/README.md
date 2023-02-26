---
title: GCP Google Kubernetes Engine GKE Ingress Namebased Virtual Host Routing
description: Implement GCP Google Kubernetes Engine GKE Ingress Namebased Virtual Host Routing
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
1. Requests will be routed in Load Balancer based on DNS Names
2. `app1-ingress.kalyanreddydaida.com` will send traffic to `App1 Pods`
3. `app2-ingress.kalyanreddydaida.com` will send traffic to `App2 Pods`
4. `default-ingress.kalyanreddydaida.com` will send traffic to `App3 Pods`


## Step-02: Review kube-manifests
1. 01-Nginx-App1-Deployment-and-NodePortService.yaml
2. 02-Nginx-App2-Deployment-and-NodePortService.yaml
3. 03-Nginx-App3-Deployment-and-NodePortService.yaml
4. NO CHANGES TO ABOVE 3 files - Standard Deployment and NodePort Service we are using from previous Context Path based Routing Demo


## Step-03: 04-Ingress-NameBasedVHost-Routing.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-namebasedvhost-routing
  annotations:
    # External Load Balancer
    kubernetes.io/ingress.class: "gce"  
    # Static IP for Ingress Service
    kubernetes.io/ingress.global-static-ip-name: "gke-ingress-extip1"   
    # Google Managed SSL Certificates
    networking.gke.io/managed-certificates: managed-cert-for-ingress
    # SSL Redirect HTTP to HTTPS
    networking.gke.io/v1beta1.FrontendConfig: "my-frontend-config"   
    # External DNS - For creating a Record Set in Google Cloud Cloud DNS
    external-dns.alpha.kubernetes.io/hostname: default-ingress.kalyanreddydaida.com
spec:          
  defaultBackend:
    service:
      name: app3-nginx-nodeport-service
      port:
        number: 80     
  rules:
    - host: app1-ingress.kalyanreddydaida.com
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: app1-nginx-nodeport-service
                port: 
                  number: 80
    - host: app2-ingress.kalyanreddydaida.com
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

## Step-04: 05-Managed-Certificate.yaml
```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: managed-cert-for-ingress
spec:
  domains:
    - default101-ingress.kalyanreddydaida.com
    - app101-ingress.kalyanreddydaida.com
    - app201-ingress.kalyanreddydaida.com
```

## Step-05: 06-frontendconfig.yaml
```yaml
apiVersion: networking.gke.io/v1beta1
kind: FrontendConfig
metadata:
  name: my-frontend-config
spec:
  redirectToHttps:
    enabled: true
    #responseCodeName: RESPONSE_CODE
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

# List Managed Certificates
kubectl get managedcertificate

# Describe Managed Certificates
kubectl describe managedcertificate managed-cert-for-ingress
Observation:
1. Wait for Domain Status to be changed from "Provisioning" to "ACTIVE"
2. It might take minimum 60 minutes for provisioning Google Managed SSL Certificates
```

## Step-07: Access Application
```t
# Access Application
http://app1-ingress.kalyanreddydaida.com/app1/index.html
http://app2-ingress.kalyanreddydaida.com/app2/index.html
http://default-ingress.kalyanreddydaida.com

Observation:
1. All 3 URLS should work as expected. In your case, replace YOUR_DOMAIN name for testing
2. HTTP to HTTPS redirect should work
```

## Step-08: Access Application - Negative usecase Testing
```t
# Access Application - App1 DNS Name
http://app1-ingress.kalyanreddydaida.com/app2/index.html   
Observation: SHOULD FAIL In Pod App1 we don't app2 context path (app2 folder) - 404 ERROR

# Access Application - App2 DNS Name
http://app2-ingress.kalyanreddydaida.com/app1/index.html
Observation: SHOULD FAIL In Pod App2 we don't app1 context path (app1 folder) - 404 ERROR

# Access Application - App3 or Default DNS Name
http://default-ingress.kalyanreddydaida.com/app1/index.html
Observation: SHOULD FAIL In Pod App3 we don't app1 context path (app1 folder) - 404 ERROR
```

## Step-09: Clean-Up
- DONT DELETE, WE ARE GOING TO USE THESE KUBERNETES RESOURCES IN NEXT DEMO RELATED TO SSL-POLICY

## References
- [Ingress Features](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features)


