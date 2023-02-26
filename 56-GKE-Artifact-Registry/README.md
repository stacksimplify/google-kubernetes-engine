---
title: GCP Google Kubernetes Engine GKE Artifact Registry
description: Implement GCP Google Kubernetes Engine GKE Artifact Registry
---

## Step-00: Pre-requisites
1. Verify if GKE Cluster is created
2. Verify if kubeconfig for kubectl is configured in your local terminal.
```t
# Configure kubeconfig for kubectl
gcloud container clusters get-credentials <CLUSTER-NAME> --region <REGION> --project <PROJECT>

# Replace Values CLUSTER-NAME, REGION, PROJECT
gcloud container clusters get-credentials standard-cluster-private-1 --region us-central1 --project kdaida123

# List Kubernetes Nodes
kubectl get nodes
```

## Step-01: Introduction
- Build a Docker Image
- Create a Docker repository in Google Artifact Registry.
- Set up authentication.
- Push an image to the repository.
- Pull the image from the repository and Create Deployment in GKE Cluster
- Access Sample Application in browser and verify


## Step-02: Create Dockefile
- **Dockerfile**
```t
FROM nginx
COPY index.html /usr/share/nginx/html
```

## Step-03: Build Docker Image
```t
# Change Directory
cd google-kubernetes-engine/56-GKE-Artifact-Registry/
cd 01-Docker-Image

# Build Docker Image
docker build -t myapp1:v1 .

# List Docker Image
docker images myapp1
```

## Step-04: Run Docker Image
```t
# Run Docker Image
docker run --name myapp1 -p 80:80 -d myapp1:v1

# Access in browser
http://localhost

# List Running Docker Containers
docker ps

# Stop Docker Container
docker stop myapp1

# List All Docker Containers (Stopped Containers)
docker ps -a

# Delete Stopped Container
docker rm myapp1

# List All Docker Containers (Stopped Containers)
docker ps -a
```

## Step-05: Create Google Artifact Registry
- Go to Artifact Registry -> Repositories -> Create
```t
# Create Google Artifact Registry 
Name: gke-artifact-repo1
Format: Docker
Region: us-central-1
Encryption: Google-managed encryption key
Click on Create
```

## Step-06: Configure Google Artifact Repository authentication
```t
# Google Artifact Repository authentication
## To set up authentication to Docker repositories in the region us-central1
gcloud auth configure-docker <LOCATION>-docker.pkg.dev
gcloud auth configure-docker us-central1-docker.pkg.dev
```

## Step-07: Tag & push the Docker image to Google Artifact Registry
```t
# Tag the Docker Image
docker tag myapp1:v1 <LOCATION>-docker.pkg.dev/<GOOGLE-PROJECT-ID>/<GOOGLE-ARTIFACT-REGISTRY-NAME>/<IMAGE-NAME>:<IMAGE-TAG>

# Replace Values for docker tag command 
# - LOCATION, 
# - GOOGLE-PROJECT-ID, 
# - GOOGLE-ARTIFACT-REGISTRY-NAME, 
# - IMAGE-NAME, 
# - IMAGE-TAG
docker tag myapp1:v1 us-central1-docker.pkg.dev/kdaida123/gke-artifact-repo1/myapp1:v1

# Push the Docker Image to Google Artifact Registry
docker push us-central1-docker.pkg.dev/kdaida123/gke-artifact-repo1/myapp1:v1
```

## Step-08: Verify the Docker Image on Google Artifact Registry
- Go to Google Artifact Registry -> Repositories -> gke-artifact-repo1
- Review **myapp1** Docker Image

## Step-09: Update Docker Image and Review kube-manifests
- **Project-Folder:** 02-kube-manifests
```yaml
# Dcoker Image
image: us-central1-docker.pkg.dev/<GCP-PROJECT-ID>/<ARTIFACT-REPO>/myapp1:v1

# Update Docker Image in 01-kubernetes-deployment.yaml
image: us-central1-docker.pkg.dev/kdaida123/gke-artifact-repo1/myapp1:v1
```

## Step-10: Deploy kube-manifests
```t
# Deploy kube-manifests
kubectl apply -f 02-kube-manifests

# List Deployments
kubectl get deploy

# List Pods
kubectl get pods

# Describe Pod
kubectl describe pod <POD-NAME>

## Observation - Verify Events command "kubectl describe pod <POD-NAME>"
### We should see image pulled from "us-central1-docker.pkg.dev/kdaida123/gke-artifact-repo1/myapp1:v1"
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  86s   default-scheduler  Successfully assigned default/myapp1-deployment-5f8d5c6f48-pb686 to gke-standard-cluster-1-default-pool-2c852f67-46hv
  Normal  Pulling    85s   kubelet            Pulling image "us-central1-docker.pkg.dev/kdaida123/gke-artifact-repo1/myapp1:v1"
  Normal  Pulled     81s   kubelet            Successfully pulled image "us-central1-docker.pkg.dev/kdaida123/gke-artifact-repo1/myapp1:v1" in 4.285567138s
  Normal  Created    81s   kubelet            Created container myapp1-container
  Normal  Started    80s   kubelet            Started container myapp1-container
Kalyans-MacBook-Pro:41-GKE-Artiact-Registry kdaida$ 


# List Services
kubectl get svc

# Access Application
http://<SVC-EXTERNAL-IP>
```

## Step-11: Clean-Up
```t
# Undeploy sample App
kubectl delete -f 02-kube-manifests
```


## References
- [Google Artifact Registry](https://cloud.google.com/artifact-registry/docs/overview)