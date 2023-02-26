---
title: GCP Google Kubernetes Engine GKE CI
description: Implement GCP Google Kubernetes Engine GKE Continuous Integration
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


## Step-01: Introduction
- Implement Continuous Integration for GKE Workloads using
- Google Cloud Source
- Google Cloud Build
- Google Artifact Repository


## Step-02: Enable APIs in Google Cloud
```t
# Enable APIs in Google Cloud
gcloud services enable container.googleapis.com \
    cloudbuild.googleapis.com \
    sourcerepo.googleapis.com \
    artifactregistry.googleapis.com

# Google Cloud Services 
GKE: container.googleapis.com     
Cloud Build: cloudbuild.googleapis.com
Cloud Source: sourcerepo.googleapis.com
Artifact Registry: artifactregistry.googleapis.com
```

## Step-03: Create Artifact Repository
```t
# List Artifact Repositories
gcloud artifacts repositories list

# Create Artifact Repository
gcloud artifacts repositories create myapps-repository \
  --repository-format=docker \
  --location=us-central1 

# List Artifact Repositories
gcloud artifacts repositories list

# Describe Artifact Repository 
gcloud artifacts repositories describe myapps-repository --location=us-central1
```

## Step-04: Install Git client on local desktop (if not present)
```t
# Download and Install Git Client and Installed
https://git-scm.com/downloads
```

## Step-05: Create SSH Keys for Git Repo Access
- [Generating SSH Key Pair](https://cloud.google.com/source-repositories/docs/authentication#generate_a_key_pair)
```t
# Change Directory
cd 01-SSH-Keys

# Create SSH Keys
ssh-keygen -t [KEY_TYPE] -C "[USER_EMAIL]"
KEY_TYPE: rsa, ecdsa, ed25519
USER_EMAIL: dkalyanreddy@gmail.com 

# Replace Values KEY_TYPE, USER_EMAIL
ssh-keygen -t ed25519 -C "dkalyanreddy@gmail.com"
Provide the File Name as "id_gcp_cloud_source"

## Sample Output
Kalyans-Mac-mini:01-SSH-Keys kalyanreddy$ ssh-keygen -t ed25519 -C "dkalyanreddy@gmail.com"
Generating public/private ed25519 key pair.
Enter file in which to save the key (/Users/kalyanreddy/.ssh/id_ed25519): id_gcp_cloud_source
Enter passphrase (empty for no passphrase): 
Enter same passphrase again: 
Your identification has been saved in id_gcp_cloud_source
Your public key has been saved in id_gcp_cloud_source.pub
The key fingerprint is:
SHA256:YialyCj3XaSa4b8ewk4bcK1hXxO7DDM5uiCP1J2TOZ0 dkalyanreddy@gmail.com
The key's randomart image is:
+--[ED25519 256]--+
|                 |
|                 |
|      . o        |
| o . + + o       |
|o = B % S        |
|...B.&=X.o       |
|....%B+Eo        |
|.+ + *o.         |
|. . +.+.         |
+----[SHA256]-----+
Kalyans-Mac-mini:01-SSH-Keys kalyanreddy$ ls -lrta
total 16
drwxr-xr-x  6 kalyanreddy  staff  192 Jun 29 09:45 ..
-rw-------  1 kalyanreddy  staff  419 Jun 29 09:46 id_gcp_cloud_source
drwxr-xr-x  4 kalyanreddy  staff  128 Jun 29 09:46 .
-rw-r--r--  1 kalyanreddy  staff  104 Jun 29 09:46 id_gcp_cloud_source.pub
Kalyans-Mac-mini:01-SSH-Keys kalyanreddy$ 
```

## Step-06: Review SSH Keys (Public and Private Keys)
```t
# Change Directroy 
cd 01-SSH-Keys

# Review Private Key: id_gcp_cloud_source
cat id_gcp_cloud_source

# Review Public Key: id_gcp_cloud_source.pub 
cat id_gcp_cloud_source.pub 
```

## Step-07: Update SSH Public Key in Google Cloud Source
- Go to -> Source Repositories -> 3 Dots -> Manage SSH Keys -> Register SSH Key
- [Google Cloud Source URL](https://source.cloud.google.com/)
```t
# Key Name
Name: gke-course
Key: Output from command "cat id_gcp_cloud_source.pub" in previous step. Put content from Public Key
```
- Click on **Register**


## Step-08: Update SSH Private Key in Git Config
- Update SSH Private Key in your local desktop Git Config
```t
# Copy SSH Private Key to your ".ssh" folder in your Home Directory from your course
cd 01-SSH-Keys
cp id_gcp_cloud_source $HOME/.ssh  

# Change Directory (Your local desktop home directory)
cd $HOME/.ssh  

# Verify File in "$HOME/.ssh"
ls -lrta id_gcp_cloud_source

# Verify existing git "config" file
cat config

# Backup any existing "config" file
cp config config_bkup_before_cloud_source

# Update "config" file to point to "id_gcp_cloud_source" private key
vi config

## Sample Output after changes
Kalyans-Mac-mini:.ssh kalyanreddy$ cat config
Host *
  AddKeysToAgent yes
  UseKeychain yes
  IdentityFile ~/.ssh/id_gcp_cloud_source
Kalyans-Mac-mini:.ssh kalyanreddy$ 

# Backup config with cloudsource
cp config config_with_cloud_source_key
```

## Step-09: Update Git Global Config in your local deskopt
```t
# List Global Git Config
git config --list

# Update Global Git Config
git config --global user.email "YOUR_EMAIL_ADDRESS"
git config --global user.name "YOUR_NAME"

# Replace YOUR_EMAIL_ADDRESS, YOUR_NAME
git config --global user.name "Kalyan Reddy Daida"
git config --global user.email "dkalyanreddy@gmail.com"

# List Global Git Config
git config --list
```

## Step-10: Create Git repositories in Cloud Source
```t
# List Cloud Source Repository
gcloud source repos list

# Create Git repositories in Cloud Source
gcloud source repos create myapp1-app-repo

# List Cloud Source Repository
gcloud source repos list

# Verify using Cloud Console
Search for -> Source Repositories 
https://source.cloud.google.com/repos
```

## Step-11: Clone Cloud Source Git Repository, Commit a Change, Push to Remote Repo and Verify
```t
# Change Directory 
cd course-repos

# Verify using Cloud Console
Search for -> Source Repositories 
https://source.cloud.google.com/repos
Go to Repo -> myapp1-app-repo -> SSH Authentication

# Copy the git clone command and run 
git clone ssh://dkalyanreddy@gmail.com@source.developers.google.com:2022/p/kdaida123/r/myapp1-app-repo

# Change Directory
cd myapp1-app-repo

# Create a simple readme file
touch README.md
echo "# GKE CI Demo" > README.md
ls -lrta

# Add Files and do local commit
git add .
git commit -am "First Commit"

# Push file to Cloud Source Git Repo (Remote Repo)
git push

# Verify in Git Remote Repo
Search for -> Source Repositories 
https://source.cloud.google.com/repos
Go to Repo -> myapp1-app-repo 
```

## Step-12: Review Files in 02-Docker-Image folder
1. Dockerfile
2. index.html

## Step-13: Copy files from 02-Docker-Image folder to Git Repo
```t
# Change Directroy 
cd 57-GKE-Continuous-Integration/02-Docker-Image

# Copy Files to Git repo "myapp1-app-repo"
1. Dockerfile
2. index.html

# Local Git Commit and Push to Remote Repo
git add .
git commit -am "Second Commit"
git push

# Verify in Git Remote Repo
Search for -> Source Repositories 
https://source.cloud.google.com/repos
Go to Repo -> myapp1-app-repo 
```

## Step-14: Create a container image with Cloud Build and store it in Artifact Registry using glcoud builds command
```t
# Change Directory (Git App Repo: myapp1-app-repo)
cd myapp1-app-repo

# Get latest git commit id (current branch)
git rev-parse HEAD

# Get latest git commit id first 7 chars (current branch)
git rev-parse --short=7 HEAD

# Ensure you are in local git repo folder where "Dockerfile, index.html" present
cd myapp1-app-repo 

# Create a Cloud Build build based on the latest commit 
gcloud builds submit --tag="us-central1-docker.pkg.dev/${PROJECT_ID}/${$APP_ARTIFACT_REPO}/myapp1:${COMMIT_ID}" .

# Replace Values ${PROJECT_ID}, ${$APP_ARTIFACT_REPO}, ${COMMIT_ID}
gcloud builds submit --tag="us-central1-docker.pkg.dev/kdaida123/myapps-repository/myapp1:6f7d338" .
```

## Step-15: Review Cloud Build YAML file
```yaml
steps:
# This step builds the container image.
- name: 'gcr.io/cloud-builders/docker'
  id: Build
  args:
  - 'build'
  - '-t'
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/myapps-repository/myapp1:$SHORT_SHA'
  - '.'

# This step pushes the image to Artifact Registry
# The PROJECT_ID and SHORT_SHA variables are automatically
# replaced by Cloud Build.
- name: 'gcr.io/cloud-builders/docker'
  id: Push
  args:
  - 'push'
  - 'us-central1-docker.pkg.dev/$PROJECT_ID/myapps-repository/myapp1:$SHORT_SHA'
```

## Step-16: Copy cloudbuild.yaml to Git Repo
```t
# Change Directroy 
cd 57-GKE-Continuous-Integration/03-cloudbuild-yaml

# Copy Files to Git repo
1. cloudbuild.yaml

# Local Git Commit and Push to Remote Repo
git add .
git commit -am "Third Commit"
git push

# Verify in Git Remote Repo
Search for -> Source Repositories 
https://source.cloud.google.com/repos
Go to Repo -> myapp1-app-repo 
```

## Step-17: Create Continuous Integration Pipeline in Cloud Build
- Go to Cloud Build -> Dashboard -> Region: us-central-1 -> Click on **SET UP BUILD TRIGGERS** [OR]
- Go to Cloud Build -> TRIGGERS -> Click on **CREATE TRIGGER** 
- **Name:** myapp1-ci
- **Region:** us-central1
- **Description:** myapp1 Continuous Integration Pipeline
- **Tags:** environment=dev
- **Event:** Push to a branch
- **Source:** myapp1-app-repo
- **Branch:** main (Auto-populated)
- **Configuration:** Cloud Build configuration file (yaml or json)
- **Location:** Repository
- **Cloud Build Configuration file location:** /cloudbuild.yaml
- **Approval:** leave unchecked
- **Service account:** leave to default
- Click on **CREATE**


## Step-18: Make a simple change in "index.html" and push the changes to Git Repo
```t
# Change Directroy 
cd myapp1-app-repo

# Update file index.html (change V1 to V2)
<p>Application Version: V2</p>

# Local Git Commit and Push to Remote Repo
git status
git add .
git commit -am "V2 Commit"
git push

# Verify in Git Remote Repo
Search for -> Source Repositories 
https://source.cloud.google.com/repos
Go to Repo -> myapp1-app-repo 
```

## Step-19: Verify Code Build CI Pipeline
```t
# Verify Code Build
1. Go to Code Build -> Dashboard or go directly to Code Build -> History
2. Click on Build History -> View All
3. Verify "BUILD LOG"
4. Verify "EXECUTION DETAILS"
5. Verify "VIEW RAW"

# Verify Artifact Repository
1. Go to Artifact Registry -> myapps-repository -> myapp1
2. You should find the docker image pushed to Artifact Registry
```

## Step-20: Review Kubernetes Manifests
- **Project Folder:** 04-kube-manifests
- 01-kubernetes-deployment.yaml
- 02-kubernetes-loadBalancer-service.yaml

## Step-21: Update Container Image to V1 Docker Image we built
```yaml
# 01-kubernetes-deployment.yaml: Update "image" 
    spec:
      containers: # List
        - name: myapp1-container
          image: us-central1-docker.pkg.dev/kdaida123/myapps-repository/myapp1:d1c3b88
          ports: 
            - containerPort: 80  
```

## Step-22: Deploy Kubernetes Manifests and Verify
```t
# Change Directory
You should in Course Content folder 
google-kubernetes-engine/<RESPECTIVE-SECTION>

# Deploy Kubernetes Manifests
kubectl apply -f 04-kube-manifests

# List Deployments
kubectl get deploy

# List Pods
kubectl get pods

# Describe Pod (Review Events to understand from where Docker Image downloaded)
kubectl describe pod <POD-NAME>

# List Services
kubectl get svc

# Access Application
http://<EXTERNAL-IP-GET-SERVICE-OUTPUT>
Observation:
1. You should see "Application Version: V1"
```

## Step-23: Update Container Image to V2 Docker Image we built
```yaml
# 01-kubernetes-deployment.yaml: Update "image" 
    spec:
      containers: # List
        - name: myapp1-container
          image: us-central1-docker.pkg.dev/kdaida123/myapps-repository/myapp1:3af592c
          ports: 
            - containerPort: 80  
```

## Step-24: Update Kubernetes Deployment and Verify
```t
# Deply Kubernetes Manifests (Updated Image Tag)
kubectl apply -f 04-kube-manifests

# Restart Kubernetes Deployment (Optional - if it is not updated)
kubectl rollout restart deployment myapp1-deployment

# List Deployments
kubectl get deploy

# List Pods
kubectl get pods

# Describe Pod (Review Events to understand from where Docker Image downloaded)
kubectl describe pod <POD-NAME>

# List Services
kubectl get svc

# Access Application
http://<EXTERNAL-IP-GET-SERVICE-OUTPUT>
Observation:
1. You should see "Application Version: V2"
```

## Step-25: Clean-Up
```t
# Delete Kubernetes Resources
kubectl delete -f 04-kube-manifests
```

## Step-26: How to add Approvals before starting the Build Process ?
### Step-26-01: Enable Approval in Cloud Build
- Go to Cloud Build -> Triggers -> myapp1-ci
- Check the box in **Approval: Require approval before build executes**

### Step-26-02: Add Users to Cloud Build Approver IAM Role
- Go to IAM & Admin -> GRANT ACCESS 
- **Add Principal:** dkalyanreddy@gmail.com
- **Assign Roles:** Cloud Build Approver
- Click on **SAVE**

## Step-27: Update the Git Repo to test Build Approval Process
```t
# Change Directroy 
cd myapp1-app-repo

# Update file index.html (change V2 to V3)
<p>Application Version: V3</p>

# Local Git Commit and Push to Remote Repo
git status
git add .
git commit -am "V3 Commit"
git push

# Verify in Git Remote Repo
Search for -> Source Repositories 
https://source.cloud.google.com/repos
Go to Repo -> myapp1-app-repo 
```

## Step-28: Verify and Approve the Build
- Go to Cloud Build -> Triggers -> myapp1-ci -> Select and Approve
- Verify if build is successful.




## References
- [Cloud Build for Docker Images](https://cloud.google.com/kubernetes-engine/docs/tutorials/gitops-cloud-build)