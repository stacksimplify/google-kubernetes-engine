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
3. Create pre-shared certificates in Google Cloud using `gcloud compute ssl-certificates create` 
4. Reference these pre-shared certificates in Ingress Service using Annotation `ingress.gcp.kubernetes.io/pre-shared-cert: "app1-ingress,app2-ingress,app3-ingress"`

## Step-02: Creating pre-shared certificates in Google Cloud
```t
# List SSL Certificates
gcloud compute ssl-certificates list

# Change Directory 
cd SSL-SelfSigned-Certs
Observation: We should find certificates we have created in previous Self Signed Certs Demo

# App1 - Create a certificate resource in your Google Cloud project:
gcloud compute ssl-certificates create app1-ingress --certificate app1-ingress.crt  --private-key app1-ingress.key

# App2 - Create a certificate resource in your Google Cloud project:
gcloud compute ssl-certificates create app2-ingress --certificate app2-ingress.crt  --private-key app2-ingress.key

# App3 - Create a certificate resource in your Google Cloud project:
gcloud compute ssl-certificates create app3-ingress --certificate app3-ingress.crt  --private-key app3-ingress.key

# List SSL Certificates
gcloud compute ssl-certificates list
```


## Step-03: No changes to following kube-manifests from previous Ingress Name Based Virtual Host Routing Demo
1. 01-Nginx-App1-Deployment-and-NodePortService.yaml
2. 02-Nginx-App2-Deployment-and-NodePortService.yaml
3. 03-Nginx-App3-Deployment-and-NodePortService.yaml
4. 05-frontendconfig.yaml

## Step-04: Review 04-ingress-preshared-ssl.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-preshared-ssl
  annotations:
    # External Load Balancer
    kubernetes.io/ingress.class: "gce"  
    # Static IP for Ingress Service
    kubernetes.io/ingress.global-static-ip-name: "gke-ingress-extip1"   
    # SSL Redirect HTTP to HTTPS
    networking.gke.io/v1beta1.FrontendConfig: "my-frontend-config"   
    # External DNS - For creating a Record Set in Google Cloud Cloud DNS
    external-dns.alpha.kubernetes.io/hostname: app3-default.kalyanreddydaida.com
    # Pre-shared certificate resources  
    ingress.gcp.kubernetes.io/pre-shared-cert: "app1-ingress,app2-ingress,app3-ingress"
spec: 
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

# List Ingress Services
kubectl get ingress

# Describe Ingress Service
kubectl describe ingress ingress-preshared-ssl

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
1. Load Balancers View -> In FRONTENDS -> Certificate
2. Load Balancers Components View -> CERTIFICATEs Tab
3. Load Balancers Components View -> TARGET PROXIES -> HTTPS Proxy -> SSL Certificates
```

## Step-06: Access Application
```t
# Access Application
http://app1.kalyanreddydaida.com/app1/index.html  --> VIEW CERTIFICATE WHEN ACCESSING URL
http://app2.kalyanreddydaida.com/app2/index.html  --> VIEW CERTIFICATE WHEN ACCESSING URL
http://app3-default.kalyanreddydaida.com          --> VIEW CERTIFICATE WHEN ACCESSING URL

Observation:
1. All 3 URLS should work as expected. In your case, replace YOUR_DOMAIN name for testing
2. HTTP to HTTPS redirect should work
3. You will get a warning "The certificate is not trusted because it is self-signed.". Click on "Accept the risk and continue"
```

## Step-07: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests
```

## Step-08: Clean-Up SSL Certs from your Google Cloud Project
```t
# List SSL Certificates
gcloud compute ssl-certificates list

# Delete SSL Certificates
gcloud compute ssl-certificates delete app1-ingress
gcloud compute ssl-certificates delete app2-ingress
gcloud compute ssl-certificates delete app3-ingress

# List SSL Certificates
gcloud compute ssl-certificates list

# Verify SSL Certificates In Load Balancing Section
Go to Load Balancers
1. Load Balancers Components View -> CERTIFICATEs Tab
```

## References
- [Ingress Pre-shared Certificates](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-multi-ssl#pre-shared-certs)


