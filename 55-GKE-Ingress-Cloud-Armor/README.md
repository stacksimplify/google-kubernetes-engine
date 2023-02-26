---
title: GCP Google Kubernetes Engine GKE Ingress with Cloud Armor
description: Implement GCP Google Kubernetes Engine GKE Ingress with Cloud Armor
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

3. Registered Domain using Google Cloud Domains
4. External DNS Controller installed and ready to use
```t
# List External DNS Pods
kubectl -n external-dns-ns get pods
```
5. Verify if External IP Address is created
```t
# List External IP Address
gcloud compute addresses list

# Describe External IP Address 
gcloud compute addresses describe gke-ingress-extip1 --global
```


## Step-01: Introduction
- Ingress Service with Cloud Armor

## Step-02: Create Cloud Armor Policy
- Go to Network Security -> Cloud Armor -> CREATE POLICY
### Configure Policy
- **Name:** cloud-armor-policy-1
- **Description:** Cloud Armor Demo with GKE Ingress
- **Policy type:** Backend security policy
- **Default rule action:** Deny
- **Deny Status:** 403(Forbidden)
- Click on **NEXT STEP**
### Add More Rules (Optional)
- Leave to default 
- NO NEW RULES OTHER THAN EXISTING DEFAULT RULE
- ALL IP ADDRESS -> DENY -> With 403 ERROR -> Priority 2,147,483,647	
- Click on **NEXT STEP**
### Add Policy to Targets (Optional)
- Leave to default 
- Click on **NEXT STEP**
### Advanced configurations (Adaptive Protection) (optional)
- Click on **Enable** checkbox
- Click on **DONE**
- Click on **CREATE POLICY**

## Step-03: 01-kubernetes-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloud-armor-demo-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cloud-armor-demo
  template:
    metadata:
      labels:
        app: cloud-armor-demo
    spec:
      containers:
        - name: cloud-armor-demo
          image: stacksimplify/kubenginx:1.0.0
          ports:
            - containerPort: 80
          # Readiness Probe (https://cloud.google.com/kubernetes-engine/docs/concepts/ingress#def_inf_hc)            
          readinessProbe:
            httpGet:
              scheme: HTTP
              path: /index.html
              port: 80
            initialDelaySeconds: 10
            periodSeconds: 15
            timeoutSeconds: 5    
```
## Step-04: 02-kubernetes-NodePort-service.yaml
```yaml
apiVersion: v1
kind: Service
metadata:
  name: cloud-armor-demo-nodeport-service
  annotations:
    cloud.google.com/backend-config: '{"ports": {"80":"my-backendconfig"}}'
spec:
  type: NodePort
  selector:
    app: cloud-armor-demo
  ports:
    - port: 80
      targetPort: 80
```
## Step-05: 03-ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-cloud-armor-demo
  annotations:
    # External Load Balancer
    kubernetes.io/ingress.class: "gce"  
    # Static IP for Ingress Service
    kubernetes.io/ingress.global-static-ip-name: "gke-ingress-extip1"   
    # External DNS - For creating a Record Set in Google Cloud Cloud DNS
    external-dns.alpha.kubernetes.io/hostname: cloudarmor-ingress.kalyanreddydaida.com
spec:          
  defaultBackend:
    service:
      name: cloud-armor-demo-nodeport-service
      port:
        number: 80     

```
## Step-06: 04-backendconfig.yaml
```yaml
apiVersion: cloud.google.com/v1
kind: BackendConfig
metadata:
  name: my-backendconfig
spec:
  timeoutSec: 42 # Backend service timeout: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#timeout
  connectionDraining: # Connection draining timeout: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#draining_timeout
    drainingTimeoutSec: 62
  logging: # HTTP access logging: https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#http_logging
    enable: true
    sampleRate: 1.0
  securityPolicy:
    name: "cloud-armor-policy-1"
```
## Step-07: Deploy Kubernetes Manifests and Verify
```t
# Deploy Kubernetes Manifests
kubectl apply -f kube-manifests

# List Deployments
kubectl get deploy

# List Pods
kubectl get po

# List Services
kubectl get svc

# List Ingress Services
kubectl get ingress

# List Backendconfig
kubectl get backendconfig

# Access Application
http://<DNS-NAME>
http://cloudarmor-ingress.kalyanreddydaida.com
Observation:
1. We should get 403 Forbidden error.
2. This is expected because we have configured a Cloud Armor Policy to block All IP Addresses with 403 Error
```

## Step-08: Make a note of Public IP for your Internet Connection
- Go to [URL: www.whatismyip.com](https://www.whatismyip.com/) and make a note of your local desktop Public IP
- If you are behind Company / Organizations proxies, not sure if it works. 
- I am using my Home Internet Connection


## Step-09: Add new rule in Cloud Armor Policy
- Go to Network Security -> Cloud Armor -> POLICIES -> cloud-armor-policy-1 -> RULES -> ADD RULE
- **Description:** Allow-from-my-desktop
- **Mode:** Basic Mode(IP Address / Ranges only)
- **Match:** 49.206.52.84 (My internet connection public ip)
- **Action:** Allow
- **Priority:** 1
- Click on **ADD**
- WAIT FOR 5 MINUTES for new policy to go live

## Step-10: Access Application
```t
# Access Application from local desktop
http://<DNS-NAME>
http://cloudarmor-ingress.kalyanreddydaida.com
curl http://cloudarmor-ingress.kalyanreddydaida.com
Observation:
1. Application access should be successful
```

## Step-11: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f kube-manifests

# Delete Cloud Armor Policy
Go to Network Security -> Cloud Armor -> POLICIES -> cloud-armor-policy-1 -> DELETE
```


## References
- https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features#cloud_armor
- https://cloud.google.com/armor/docs/security-policy-overview
- https://cloud.google.com/armor/docs/integrating-cloud-armor
- https://cloud.google.com/armor/docs/configure-security-policies