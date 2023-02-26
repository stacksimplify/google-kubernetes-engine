---
title: GCP Google Kubernetes Engine GKE Ingress SSL
description: Implement GCP Google Kubernetes Engine GKE Ingress SSL with Google Managed Certificates
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
- Certificate Validity: 90 days
- 30 days before expiry google starts renewal process. We dont need to worry about it.
- **Important Note:** Google-managed certificates are only supported with GKE Ingress using the external HTTP(S) load balancer. Google-managed certificates do not support third-party Ingress controllers.

## Step-02: kube-manifest - NO CHANGES
- 01-Nginx-App1-Deployment-and-NodePortService.yaml
- 02-Nginx-App2-Deployment-and-NodePortService.yaml
- 03-Nginx-App3-Deployment-and-NodePortService.yaml

## Step-03: 05-Managed-Certificate.yaml
- **Pre-requisite-1:** Registered Domain using Google Cloud Domains
- **Pre-requisite-2:** DNS name for which SSL Certificate should be created should already be added as DNS in Google Cloud DNS (Example: demo1.kalyanreddydaida.com)
```yaml
apiVersion: networking.gke.io/v1
kind: ManagedCertificate
metadata:
  name: managed-cert-for-ingress
spec:
  domains:
    - demo1.kalyanreddydaida.com
```

## Step-04: 04-Ingress-SSL.yaml
- Add the annotation `networking.gke.io/managed-certificates` to Ingress Service with Managed Certificate name. 
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

## Step-06: Deploy kube-manifests and Verify
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
kubectl describe ingress ingress-ssl
```

## Step-07: Verify Managed Certificates
```t
# List Managed Certificate
kubectl get managedcertificate

# Describe managed certificate
kubectl describe managedcertificate managed-cert-for-ingress
Observation: 
1. Wait for the Google-managed certificate to finish provisioning. 
2. This might take up to 60 minutes. 
3. Status of the certificate should change from PROVISIONING to ACTIVE
demo1.kalyanreddydaida.com: PROVISIONING

# List Certificates
gcloud compute ssl-certificates list
```

## Step-08: Verify SSL Certificates from Certificate Tab in Load Balancer
### Load Balancers Component View
- View in **Load Balancers Component View**
- Click on **CERTIFICATES** tab

### Load Balancers View
- Review FRONTEND with HTTPS Protocol and associated with Certificate



## Step-09: Access Application
```t
# Important Note
Wait for 2 to 3 minutes for the Load Balancer to completely create and ready for use else we will get HTTP 502 errors

# Access Application
http://<DNS-DOMAIN-NAME>/app1/index.html
http://<DNS-DOMAIN-NAME>/app2/index.html
http://<DNS-DOMAIN-NAME>/

# Note: Replace Domain Name registered in Cloud DNS
# HTTP URLs
http://demo1.kalyanreddydaida.com/app1/index.html
http://demo1.kalyanreddydaida.com/app2/index.html
http://demo1.kalyanreddydaida.com/

# HTTPS URLs
https://demo1.kalyanreddydaida.com/app1/index.html
https://demo1.kalyanreddydaida.com/app2/index.html
https://demo1.kalyanreddydaida.com/
```





## References
- https://cloud.google.com/kubernetes-engine/docs/how-to/managed-certs
- https://cloud.google.com/load-balancing/docs/ssl-certificates/troubleshooting
- https://github.com/GoogleCloudPlatform/gke-managed-certs