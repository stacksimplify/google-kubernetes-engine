---
title: GCP Google Kubernetes Engine GKE Ingress with External DNS 
description: Implement GCP Google Kubernetes Engine GKE Ingress with External DNS
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
- Ingress with External DNS
- We are going to use the Annotation `external-dns.alpha.kubernetes.io/hostname` in Ingress Service.
- DNS Recordsets will be automatically added to Google Cloud DNS using external-dns controller when Ingress Service deployed


## Step-02: 01-Nginx-App3-Deployment-and-NodePortService.yaml
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app3-nginx-deployment
  labels:
    app: app3-nginx
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app3-nginx
  template:
    metadata:
      labels:
        app: app3-nginx
    spec:
      containers:
        - name: app3-nginx
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
---
apiVersion: v1
kind: Service
metadata:
  name: app3-nginx-nodeport-service
spec:
  type: NodePort
  selector:
    app: app3-nginx
  ports:
    - port: 80
      targetPort: 80   
```

## Step-03: 02-ingress-external-dns.yaml
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-externaldns-demo
  annotations:
    # If the class annotation is not specified it defaults to "gce".
    # gce: external load balancer
    # gce-internal: internal load balancer
    kubernetes.io/ingress.class: "gce"  
    # External DNS - For creating a Record Set in Google Cloud Cloud DNS
    external-dns.alpha.kubernetes.io/hostname: ingressextdns101.kalyanreddydaida.com
spec:
  defaultBackend:
    service:
      name: app3-nginx-nodeport-service
      port:
        number: 80                  
```

## Step-04: Deploy Kubernetes Manifests and Verify
```t
# Deploy Kubernetes Manifests 
kubectl apply -f kube-manifests

# List Pods
kubectl get pods

# List Services
kubectl get svc

# List Ingress Services
kubectl get ingress

# Describe Ingress Service
kubectl describe ingress ingress-externaldns-demo

# Verify external-dns Controller logs
kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
[or]
kubectl -n external-dns-ns get pods
kubectl -n external-dns-ns logs -f <External-DNS-Pod-Name>

# Verify Cloud DNS
1. Go to Network Services -> Cloud DNS -> kalyanreddydaida-com
2. Verify Record sets, DNS Name we added in Ingress Service should be present 

# Access Application
http://<DNS-Name>
http://ingressextdns101.kalyanreddydaida.com
```

## Step-05: Delete kube-manifests
```t
# Delete Kubernetes Objects
kubectl delete -f kube-manifests/

# Verify external-dns Controller logs
kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
[or]
kubectl -n external-dns-ns get pods
kubectl -n external-dns-ns logs -f <External-DNS-Pod-Name>


# Verify Cloud DNS
1. Go to Network Services -> Cloud DNS -> kalyanreddydaida-com 
2. Verify Record sets, DNS Name we added in Ingress Service should be not preset (already deleted) 
```



