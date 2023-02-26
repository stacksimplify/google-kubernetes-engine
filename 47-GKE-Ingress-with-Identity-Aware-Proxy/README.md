---
title: GCP Google Kubernetes Engine GKE Ingress with Identity Aware Proxy
description: Implement GCP Google Kubernetes Engine GKE Ingress with Identity Aware Proxy
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
3.  External DNS Controller should be installed and ready to use

## Step-01: Introduction
1. Configuring the OAuth consent screen
2. Creating OAuth credentials
3. Setting up IAP access
4. Creating a Kubernetes Secret with OAuth Client ID Credentials
5. Adding an iap block to the BackendConfig

## Step-02: Create basic google gmail users (if not present)
- I have created below two users for this IAP Demo
    - gcpuser901@gmail.com
    - gcpuser902@gmail.com

## Step-03: Enabling IAP for GKE
- [Enabling IAP for GKE](https://cloud.google.com/iap/docs/enabling-kubernetes-howto)
- We will follow steps from above documentation link to create below 2 items
    1. [Configuring the OAuth consent screen](https://cloud.google.com/iap/docs/enabling-kubernetes-howto#oauth-configure)
    2. [Creating OAuth credentials](https://cloud.google.com/iap/docs/enabling-kubernetes-howto#oauth-credentials)


```t
# Make a note of Client ID and Client Secret
Client ID: 1057267725005-0icbqnab9rsvodgmq7dicfvs1f56sj5p.apps.googleusercontent.com
Client Secret: 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

# Template
https://iap.googleapis.com/v1/oauth/clientIds/CLIENT_ID:handleRedirect

# Replace CLIENT_ID (Update URL in OAuth 2.0 Client IDs -> gke-ingress-iap-demo-oauth-creds)
https://iap.googleapis.com/v1/oauth/clientIds/1057267725005-0icbqnab9rsvodgmq7dicfvs1f56sj5p.apps.googleusercontent.com:handleRedirect
```

## Step-04: Creating a Kubernetes Secret
```t
# Make a note of Client ID and Client Secret
Client ID: 1057267725005-0icbqnab9rsvodgmq7dicfvs1f56sj5p.apps.googleusercontent.com
Client Secret: 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

# List Kubernetes Secrets (Default Namespace)
kubectl get secrets

# Create Kubernetes Secret
kubectl create secret generic my-secret --from-literal=client_id=client_id_key \
    --from-literal=client_secret=client_secret_key

# Replace  client_id_key, client_secret_key
kubectl create secret generic my-secret --from-literal=client_id=1057267725005-0icbqnab9rsvodgmq7dicfvs1f56sj5p.apps.googleusercontent.com \
    --from-literal=client_secret=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

# List Kubernetes Secrets (Default Namespace)
kubectl get secrets
```

## Step-05: Adding an iap block to the BackendConfig
- **File Name:** 07-backendconfig.yaml
```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: my-backendconfig
spec:
  iap:
    enabled: true
    oauthclientCredentials:
      secretName: my-secret    
```

## Step-06: Review Kubenertes Manifests
- All 3 Node Port Services will have annotation added `cloud.google.com/backend-config`
- 01-Nginx-App1-Deployment-and-NodePortService.yaml
- 02-Nginx-App2-Deployment-and-NodePortService.yaml
- 03-Nginx-App3-Deployment-and-NodePortService.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-nginx-nodeport-service
  labels:
    app: app1-nginx
  annotations:
    cloud.google.com/backend-config: '{"default": "my-backendconfig"}'      
spec:
  type: NodePort
  selector:
    app: app1-nginx
  ports:
    - port: 80
      targetPort: 80
```

## Step-07: Review Kubenertes Manifests
- No changes to below YAML files from previous section
- 04-Ingress-NameBasedVHost-Routing.yaml
- 05-Managed-Certificate.yaml
- 06-frontendconfig.yaml


## Step-08: Deploy Kubernetes Manifests
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests
Observation: 
1. All other configs already created as part of previous demo, only backendconfig change will be applied now. 

# List Deployments
kubectl get deploy 

# List Pods
kubectl get pods 

# List Services
kubectl get svc 

# List Ingress Services
kubectl get ingress 

# List Frontend Configs
kubectl get frontendconfig 

# List Backend Configs
kubectl get backendconfig
```

## Step-09: Setting up IAP access
- [Setting up IAP access](https://cloud.google.com/iap/docs/enabling-kubernetes-howto#iap-access)
- Add User `gcpuser901@gmail.com` as Principal.

## Step-10: Access Application
```t
# Access Application
http://app1-ingress.kalyanreddydaida.com/app1/index.html
http://app2-ingress.kalyanreddydaida.com/app2/index.html
http://default-ingress.kalyanreddydaida.com

Username: gcpuser901@gmail.com (In your case it might be a different user you added as part of Step-09)
Password: XXXXXXXXXX

Observation:
1. All 3 URLS will redirect to Google Authentication. Provide credentials to login
2. All 3 URLS should work as expected. In your case, replace YOUR_DOMAIN name for testing
3. HTTP to HTTPS redirect should work
```

## Step-11: Negative Usecase: Access using User which is not added in Principal
```t
# Access Application
http://app1-ingress.kalyanreddydaida.com/app1/index.html
http://app2-ingress.kalyanreddydaida.com/app2/index.html
http://default-ingress.kalyanreddydaida.com

Username: gcpuser902@gmail.com (user which is not added in principal as part of Step-09)
Password: XXXXXXXXXX

Observation:
1. It should fail, Application should not be accessible. 
```

## Step-12: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests

# Delete Kubernetes Secret
kubectl delete secret my-secret

# Delete OAuth Credentials
Go to API & Services -> Credentials -> OAuth 2.0 Client IDs -> gke-ingress-iap-demo-oauth-creds -> DELETE
```



## References
- [Ingress Features](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features)
- [Enabling IAP for GKE](https://cloud.google.com/iap/docs/enabling-kubernetes-howto)

