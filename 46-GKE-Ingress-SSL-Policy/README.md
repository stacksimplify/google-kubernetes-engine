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
- Implement SSL Policies in GCP and use it for Ingress Service

## Step-02: Create an SSL policy with a Google-managed profile
- [Create SSL Policies](https://cloud.google.com/load-balancing/docs/use-ssl-policies#gcloud)
```t
# List Available Features
gcloud compute ssl-policies list-available-features

# List SSL Policies
gcloud compute ssl-policies list

# Create an SSL policy with a Google-managed profile
gcloud compute ssl-policies create SSL_POLICY_NAME \
    --profile COMPATIBLE | MODERN | RESTRICTED   \
    --min-tls-version 1.0 | 1.1 | 1.2

# Replace Values  
gcloud compute ssl-policies create gke-ingress-ssl-policy --profile MODERN --min-tls-version 1.0  

# List SSL Policies
gcloud compute ssl-policies list

# Verify using Google Cloud Console
Go to Network Security -> SSL Policies -> gke-ingress-ssl-policy
```

## Step-03: Review kube-manifests
1. 01-Nginx-App1-Deployment-and-NodePortService.yaml
2. 02-Nginx-App2-Deployment-and-NodePortService.yaml
3. 03-Nginx-App3-Deployment-and-NodePortService.yaml
4. 04-Ingress-NameBasedVHost-Routing.yaml
5. 05-Managed-Certificate.yaml
4. NO CHANGES TO ABOVE 5 files - same as previous demo

## Step-04: FrontendConfig
```yaml
apiVersion: networking.gke.io/v1beta1
kind: FrontendConfig
metadata:
  name: my-frontend-config
spec:
  # HTTP to HTTPS Redirect
  redirectToHttps:
    enabled: true
    #responseCodeName: RESPONSE_CODE
  # SSL Policy
  sslPolicy: gke-ingress-ssl-policy    
```

## Step-05: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests

### Sample Output
Kalyans-Mac-mini:44-GKE-Ingress-SSL-Policy kalyanreddy$ kubectl apply -f kube-manifests
deployment.apps/app1-nginx-deployment unchanged
service/app1-nginx-nodeport-service unchanged
deployment.apps/app2-nginx-deployment unchanged
service/app2-nginx-nodeport-service unchanged
deployment.apps/app3-nginx-deployment unchanged
service/app3-nginx-nodeport-service unchanged
ingress.networking.k8s.io/ingress-namebasedvhost-routing unchanged
managedcertificate.networking.gke.io/managed-cert-for-ingress unchanged
frontendconfig.networking.gke.io/my-frontend-config configured   ----> CONFGIURED
Kalyans-Mac-mini:44-GKE-Ingress-SSL-Policy kalyanreddy$ 

# Verify Load Balancer Settings
Go to Network Services -> Load Balancing -> Load Balancer -> Settings
```

## Step-06: Dont Clean-Up
- Dont Clean-Up, We are going to use it in next section.
- To avoid delay of 1 hour for creating managed certificates, we will re-use same configs which are already created.

## References
- [Ingress Features](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features)
- [SSL Policy](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#ssl)



