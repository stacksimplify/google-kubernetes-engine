---
title: GCP Google Kubernetes Engine GKE Ingress SSL Redirect
description: Implement GCP Google Kubernetes Engine GKE Ingress SSL Redirect
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
4. DNS name for which SSL Certificate should be created should already be added as DNS in Google Cloud DNS (Example: demo1.kalyanreddydaida.com)


## Step-01: Introduction
- Google Managed Certificates for GKE Ingress
- Ingress SSL
- Ingress SSL Redirect (HTTP to HTTPS)

## Step-02: 06-frontendconfig.yaml
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

## Step-03: 04-Ingress-SSL.yaml
- Add the Annotation `networking.gke.io/v1beta1.FrontendConfig: "my-frontend-config"`
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-ssl
  annotations:
    # External Load Balancer
    kubernetes.io/ingress.class: "gce"  
    # Static IP for Ingress Service
    kubernetes.io/ingress.global-static-ip-name: "gke-ingress-extip1"   
    # Google Managed SSL Certificates
    networking.gke.io/managed-certificates: managed-cert-for-ingress
    # SSL Redirect HTTP to HTTPS
    networking.gke.io/v1beta1.FrontendConfig: "my-frontend-config"    
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

## Step-04: Deploy kube-manifests and Verify
- From previous `Ingress SSL` demo we didn't clean-up those Kubernetes resources.
- We are going use them here, in addition to previous demo in this demo we are just adding `06-frontendconfig.yaml`
```t
# Deploy Kubernetes manifests
kubectl apply -f kube-manifests
Observation:
1. Only "my-frontend-config" will be created, rest all unchanged

### Sample Output
Kalyans-Mac-mini:38-GKE-Ingress-Google-Managed-SSL-Redirect kalyanreddy$ kubectl apply -f kube-manifests/
deployment.apps/app1-nginx-deployment unchanged
service/app1-nginx-nodeport-service unchanged
deployment.apps/app2-nginx-deployment unchanged
service/app2-nginx-nodeport-service unchanged
deployment.apps/app3-nginx-deployment unchanged
service/app3-nginx-nodeport-service unchanged
ingress.networking.k8s.io/ingress-ssl configured
managedcertificate.networking.gke.io/managed-cert-for-ingress unchanged
frontendconfig.networking.gke.io/my-frontend-config created  
Kalyans-Mac-mini:38-GKE-Ingress-Google-Managed-SSL-Redirect kalyanreddy$ 


# List FrontendConfig
kubectl get frontendconfig

# Describe FrontendConfig
kubectl describe frontendconfig my-frontend-config

# List Ingress Load Balancers
kubectl get ingress

# Describe Ingress and view Rules
kubectl describe ingress ingress-ssl
```


## Step-05: Access Application
```t
# Important Note
Wait for 2 to 3 minutes for the Load Balancer to completely create and ready for use else we will get HTTP 502 errors

# Access Application
http://<DNS-DOMAIN-NAME>/app1/index.html
http://<DNS-DOMAIN-NAME>/app2/index.html
http://<DNS-DOMAIN-NAME>/

# Note: Replace Domain Name registered in Cloud DNS
# HTTP URLs: Should redirect to HTTPS URLs 
http://demo1.kalyanreddydaida.com/app1/index.html
http://demo1.kalyanreddydaida.com/app2/index.html
http://demo1.kalyanreddydaida.com/

# HTTPS URLs
https://demo1.kalyanreddydaida.com/app1/index.html
https://demo1.kalyanreddydaida.com/app2/index.html
https://demo1.kalyanreddydaida.com/
```

## Step-06: Clean Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests

# Verify Load Balancer Deleted
Go to Network Services -> Load Balancing -> No Load balancers should be present
```
