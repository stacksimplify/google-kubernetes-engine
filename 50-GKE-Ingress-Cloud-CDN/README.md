---
title: GCP Google Kubernetes Engine GKE Ingress and Cloud CDN
description: Implement GCP Google Kubernetes Engine GKE Ingress and Cloud CDN
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
- Implement following Features for Ingress Service
1. BackendConfig for Ingress Service
2. Backend Service Timeout
3. Connection Draining
4. Ingress Service HTTP Access Logging
5. Enable Cloud CDN

## Step-02: 01-kubernetes-deployment.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cdn-demo-deployment
spec:
  replicas: 2
  selector:
    matchLabels:
      app: cdn-demo
  template:
    metadata:
      labels:
        app: cdn-demo
    spec:
      containers:
        - name: cdn-demo
          image: us-docker.pkg.dev/google-samples/containers/gke/hello-app-cdn:1.0
          ports:
            - containerPort: 8080
```

## Step-03: 02-kubernetes-NodePort-service.yaml
- Update Backend Config with annotation **cloud.google.com/backend-config: '{"default": "my-backendconfig"}'**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: cdn-demo-nodeport-service
  annotations:
    cloud.google.com/backend-config: '{"default": "my-backendconfig"}'     
spec:
  type: NodePort
  selector:
    app: cdn-demo
  ports:
    - port: 80
      targetPort: 8080
```
## Step-04: 03-ingress.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-cdn-demo
  annotations:
    # External Load Balancer
    kubernetes.io/ingress.class: "gce"  
    # Static IP for Ingress Service
    kubernetes.io/ingress.global-static-ip-name: "gke-ingress-extip1"   
    # External DNS - For creating a Record Set in Google Cloud Cloud DNS
    external-dns.alpha.kubernetes.io/hostname: ingress-cdn-demo.kalyanreddydaida.com
spec:          
  defaultBackend:
    service:
      name: cdn-demo-nodeport-service
      port:
        number: 80     
```

## Step-05: 04-backendconfig.yaml
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
  cdn:
    enabled: true
    cachePolicy:
      includeHost: true
      includeProtocol: true
      includeQueryString: false  
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

# List Ingress Service
kubectl get ingress

# List Backend Config
kubectl get backendconfig
kubectl describe backendconfig my-backendconfig
```
## Step-07: Verify Settings in Load Balancer
- Go to Network Services -> Load Balancing -> Click on Load Balancer
- Go to Backend -> Backend Services
- Verify the Settings
  - **Timeout:** 42 seconds
  - **Connection draining timeout:** 62 seconds
  - **Cloud CDN:** Enabled
  - **Logging: Enabled:** (sample rate: 1)

## Step-08: Verify Cloud CDN 
- Go to Network Services -> Cloud CDN -> (Automatically created when Ingress Deployed k8s1-c6634a10-default-cdn-demo-nodeport-service-80-553facae)
- Verify Settings
  - DETAILS TAB
  - MONITORING TAB
  - CACHING TAB

## Step-09: Access Application and Verify Cache Age
```t
# Access Application
http://<DNS-NAME-FROM-INGRESS-SERVICE>
[or]
http://<IP-ADDRESS-FROM-INGRESS-SERVICE-OUTPUT>

# Access Application using DNS Name
http://ingress-cdn-demo.kalyanreddydaida.com
curl -v http://ingress-cdn-demo.kalyanreddydaida.com/?cache=true
curl -v http://ingress-cdn-demo.kalyanreddydaida.com
curl -v http://ingress-cdn-demo.kalyanreddydaida.com

## Important Note:
1. The output shows the response headers and body. 
2. In the response headers, you can see that the content was cached. The Age header tells you how many seconds the content has been cached

## Sample Output
Kalyans-Mac-mini:46-GKE-Ingress-Cloud-CDN kalyanreddy$ curl -v http://ingress-cdn-demo.kalyanreddydaida.com
*   Trying 34.120.32.120:80...
* Connected to ingress-cdn-demo.kalyanreddydaida.com (34.120.32.120) port 80 (#0)
> GET / HTTP/1.1
> Host: ingress-cdn-demo.kalyanreddydaida.com
> User-Agent: curl/7.79.1
> Accept: */*
> 
* Mark bundle as not supporting multiuse
< HTTP/1.1 200 OK
< Content-Length: 76
< Via: 1.1 google
< Date: Thu, 23 Jun 2022 04:47:42 GMT
< Content-Type: text/plain; charset=utf-8
< Age: 1625
< Cache-Control: max-age=3600,public
< 
Hello, world!
Version: 1.0.0
Hostname: cdn-demo-deployment-6f4c8f655d-htpsn
* Connection #0 to host ingress-cdn-demo.kalyanreddydaida.com left intact
Kalyans-Mac-mini:46-GKE-Ingress-Cloud-CDN kalyanreddy$ 
```

## Step-10: Verify Cloud CDN Monitoring Tab
- Go to Network Services -> Cloud CDN -> MONITORING Tab
- Review Charts
  - CDN Bandwidth
  - CDN Hit Rate
  - CDN Fill Rate
  - CDN Egress Rate
  - Requests
  - Response Codes

## Step-11: Verify Ingress Service Logs in Cloud Logging
- Go to Cloud Logging -> Logs Explorer -> Log Fields -> Select
- Resource Type: Cloud HTTP Load Balancer
- Severity: Info
- Project ID: kdaida123
- Review the logs
- Access Application and parallely review the logs
```t
# Access Application
curl -v http://ingress-cdn-demo.kalyanreddydaida.com
```

## Step-12: Verify Ingress Service Logs in Cloud Logging using Other Approach
- Go to Cloud Logging -> Logs Dashboard 
- Go to Chart -> HTTP/S Load Balancer Logs By Severity -> Click on **VIEW LOGS**


## References
- [Ingress Features](https://cloud.google.com/kubernetes-engine/docs/how-to/ingress-features)
- [Caching overview](https://cloud.google.com/cdn/docs/caching#cacheability)


