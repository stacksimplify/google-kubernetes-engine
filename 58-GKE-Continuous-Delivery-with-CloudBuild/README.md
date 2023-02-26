---
title: GCP Google Kubernetes Engine GKE CD
description: Implement GCP Google Kubernetes Engine GKE Continuous Delivery Pipeline
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
- Implement Continuous Delivery Pipeline for GKE Workloads using
- Google Cloud Source
- Google Cloud Build
- Google Artifact Repository


## Step-02: Assign Kubernetes Engine Developer IAM Role to Cloud Build
- To deploy the application in your Googke GKE Kubernetes cluster, **Cloud Build** needs the **Kubernetes Engine Developer Identity and Access Management Role.**
```t
# Verify if changes took place using Google Cloud Console    
1. Go to Cloud Build -> Settings -> SERVICE ACCOUNT -> Service account permissions
2. Kubernetes Engine	-> Should be in "DISABLED" state

# Get current project PROJECT_ID
PROJECT_ID="$(gcloud config get-value project)"
echo ${PROJECT_ID}

# Get Google Cloud Project Number
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"
echo ${PROJECT_NUMBER}

# Associate Kubernetes Engine Developer IAM Role to Cloud Build
gcloud projects add-iam-policy-binding ${PROJECT_NUMBER} \
    --member=serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com \
    --role=roles/container.developer

# Verify if changes took place using Google Cloud Console    
1. Go to Cloud Build -> Settings -> SERVICE ACCOUNT -> Service account permissions
2. Kubernetes Engine	-> Should be in "ENABLED" state
```

## Step-03: Review File cloudbuild-delivery.yaml
- **File Location:** 01-myapp1-k8s-repo
```yaml
# [START cloudbuild-delivery]
steps:
# This step deploys the new version of our container image
# in the "standard-cluster-private-1" Google Kubernetes Engine cluster.
- name: 'gcr.io/cloud-builders/kubectl'
  id: Deploy
  args:
  - 'apply'
  - '-f'
  - 'kubernetes.yaml'
  env:
  - 'CLOUDSDK_COMPUTE_REGION=us-central1'
  #- 'CLOUDSDK_COMPUTE_ZONE=us-central1-c'  
  - 'CLOUDSDK_CONTAINER_CLUSTER=standard-cluster-private-1' # Provide GKE Cluster Name

# This step copies the applied manifest to the production branch
# The COMMIT_SHA variable is automatically
# replaced by Cloud Build.
- name: 'gcr.io/cloud-builders/git'
  id: Copy to production branch
  entrypoint: /bin/sh
  args:
  - '-c'
  - |
    set -x && \
    # Configure Git to create commits with Cloud Build's service account
    git config user.email $(gcloud auth list --filter=status:ACTIVE --format='value(account)') && \
    # Switch to the production branch and copy the kubernetes.yaml file from the candidate branch
    git fetch origin production && git checkout production && \
    git checkout $COMMIT_SHA kubernetes.yaml && \
    # Commit the kubernetes.yaml file with a descriptive commit message
    git commit -m "Manifest from commit $COMMIT_SHA
    $(git log --format=%B -n 1 $COMMIT_SHA)" && \
    # Push the changes back to Cloud Source Repository
    git push origin production
# [END cloudbuild-delivery]
```
## Step-04: Create and Initialize myapp1-k8s-repo Repo, Copy Files and Push to Cloud Source Repository
```t
# Change Directory 
cd course-repos

# List Cloud Source Repositories
gcloud source repos list

# Create Cloud Source Gith Repo: myapp1-k8s-repo
gcloud source repos create myapp1-k8s-repo

# Initialize myapp1-k8s-repo Repo
gcloud source repos clone myapp1-k8s-repo

# Copy Files to myapp1-k8s-repo
cloudbuild-delivery.yaml from "58-GKE-Continuous-Delivery-with-CloudBuild/01-myapp1-k8s-repo"

# Change Directory
cd myapp1-k8s-repo

# Commit Changes
git add .
git commit -m "Create cloudbuild-delivery.yaml for k8s deployment"

# Create a candidate branch and push to be available in Cloud Source Repositories.
git checkout -b candidate
git push origin candidate

# Create a production branch and push to be available in Cloud Source Repositories.
git checkout -b production
git push origin production
```

## Step-05: Grant the Cloud Source Repository Writer IAM role to the Cloud Build service account
- Grant the Cloud Source Repository Writer IAM role to the Cloud Build service account for the **myapp1-k8s-repo** repository.

```t
# Get current project PROJECT_ID
PROJECT_ID="$(gcloud config get-value project)"
echo ${PROJECT_ID}

# GET GCP PROJECT NUMBER
PROJECT_NUMBER="$(gcloud projects describe ${PROJECT_ID} --format='get(projectNumber)')"
echo ${PROJECT_NUMBER}

# Change Directory    
cd 02-Source-Writer-IAM-Role

# Clean-Up File (put the file empty - No Content)
>myapp1-k8s-repo-policy.yaml

# Create IAM Policy YAML File
cat >myapp1-k8s-repo-policy.yaml <<EOF
bindings:
- members:
  - serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com
  role: roles/source.writer
EOF

# Verify IAM Policy File created with PROJECT_NUMBER
cat myapp1-k8s-repo-policy.yaml

# Set IAM Policy to Cloud Source Repository: myapp1-k8s-repo
gcloud source repos set-iam-policy \
    myapp1-k8s-repo myapp1-k8s-repo-policy.yaml
```

## Step-06: Create the trigger for the continuous delivery pipeline
- Go to Cloud Build -> Triggers -> Region: us-central-1 -> Click on **CREATE TRIGGER**
- **Name:** myapp1-cd
- **Region:** us-central1
- **Description:** myapp1 Continuous Deployment Pipeline
- **Tags:** environment=dev
- **Event:** Push to a branch
- **Source:** myapp1-k8s-repo
- **Branch:** candidate 
- **Configuration:** Cloud Build configuration file (yaml or json)
- **Location:** Repository
- **Cloud Build Configuration file location:** cloudbuild-delivery.yaml
- **Approval:** leave unchecked
- **Service account:** leave to default
- Click on **CREATE**


## Step-06: Review files in folder 03-myapp1-app-repo
1. Dockerfile
2. index.html
3. kubernetes.yaml.tpl
4. cloudbuild-trigger-cd.yaml
5. cloudbuild.yaml (Just a copy of cloudbuild-trigger-cd.yaml)
```yaml
# [START cloudbuild - Docker Image Build]
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
# [END cloudbuild - Docker Image Build]


# [START cloudbuild-trigger-cd]
# This step clones the myapp1-k8s-repo repository
- name: 'gcr.io/cloud-builders/gcloud'
  id: Clone myapp1-k8s-repo repository
  entrypoint: /bin/sh
  args:
  - '-c'
  - |
    gcloud source repos clone myapp1-k8s-repo && \
    cd myapp1-k8s-repo && \
    git checkout candidate && \
    git config user.email $(gcloud auth list --filter=status:ACTIVE --format='value(account)')
# This step generates the new manifest
- name: 'gcr.io/cloud-builders/gcloud'
  id: Generate Kubernetes manifest
  entrypoint: /bin/sh
  args:
  - '-c'
  - |
     sed "s/GOOGLE_CLOUD_PROJECT/${PROJECT_ID}/g" kubernetes.yaml.tpl | \
     sed "s/COMMIT_SHA/${SHORT_SHA}/g" > myapp1-k8s-repo/kubernetes.yaml
# This step pushes the manifest back to myapp1-k8s-repo
- name: 'gcr.io/cloud-builders/gcloud'
  id: Push manifest
  entrypoint: /bin/sh
  args:
  - '-c'
  - |
    set -x && \
    cd myapp1-k8s-repo && \
    git add kubernetes.yaml && \
    git commit -m "Deploying image us-central1-docker.pkg.dev/$PROJECT_ID/myapps-repository/myapp1:${SHORT_SHA}
    Built from commit ${COMMIT_SHA} of repository myapp1-app-repo
    Author: $(git log --format='%an <%ae>' -n 1 HEAD)" && \
    git push origin candidate
# [END cloudbuild-trigger-cd]
```


## Step-07: Update index.html in myapp1-app-repo, Push and Verify
```t
# Change Directory (GIT REPO)
cd myapp1-app-repo

# Update index.html
      <p>Application Version: V4</p>

# Add additional files to myapp1-app-repo
1. kubernetes.yaml.tpl
2. cloudbuild-trigger-cd.yaml
3. cloudbuild.yaml (Just a copy of cloudbuild-trigger-cd.yaml)


# Git Commit and Push to Remote Repository
git status
git add .
git commit -am "V4 Commit CI CD"
git push

# Verify Cloud Source Repository: myapp1-app-repo
https://source.cloud.google.com/
myapp1-app-repo

# Verify Cloud Source Repository: myapp1-k8s-repo
https://source.cloud.google.com/
myapp1-k8s-repo
Branch: Candidate
You should find "kubernetes.yaml" file with latest commit code for Image from "myapp1-app-repo"
```

## Step-08: Verify myapp1-ci and myapp1-cd builds
- Go to Cloud Build -> History
- Review latest **myapp1-ci** build steps
- Review latest **myapp1-cd** build steps

## Step-09: Verify Files in Cloud Source Repositories
- Go to Cloud Source 
- **myapp1-app-repo:** New files should be present
- **myapp1-k8s-repo:** kubernetes.yaml file with values replaced related to GOOGLE GOOGLE_CLOUD_PROJECT and COMMIT_SHA should be replaced `image: us-central1-docker.pkg.dev/kdaida123/myapps-repository/myapp1:2a3e72a`

## Step-10: Verify Google Artifact Registry
- Go to Artifact Registry -> Repositories -> myapps-repository -> myapp1
- Shoud see a new docker image

## Step-11: Access Application
```t
# List Pods
kubect get pods

# List Deployments
kubectl get deploy

# List Services
kubectl get svc

# Access Application
http://<SERVICE-EXTERNALIP>
Observation:
1. Should see v4 version of application deployed
```

## Step-12: Test CI CD one more time
- Update index.html to V5
```t
# Change Directory (GIT REPO)
cd myapp1-app-repo

# Update index.html
      <p>Application Version: V5</p>

# Git Commit and Push to Remote Repository
git status
git add .
git commit -am "V5 Commit CI CD"
git push

# Verify Build process
Go to Cloud Build -> myapp1-ci -> BUILD LOG 
Go to Cloud Build -> myapp1-cd -> BUILD LOG

# Access Application
http://<SERVICE-EXTERNALIP>
Observation:
1. Should see v5 version of application deployed
```

## Step-13: Verify Application Rollback by just rebuilding CD Pipeline
- Go to ANY version of `myapp1-cd` and click on `REBUILD`
- Verify by accessing Application
```t
# List Pods
kubect get pods

# List Deployments
kubectl get deploy

# List Services
kubectl get svc

# Access Application
http://<SERVICE-EXTERNALIP>
Observation:
1. Should see V4 version of application deployed
```

## Step-14: Clean-Up
```t
# Disable / Delete CI CD Pipelines
1. Go to Cloud Build -> myapp1-ci -> 3 dots -> Delete
2. Go to Cloud Build -> myapp1-cd -> 3 dots -> Delete

# Delete Cloud Source Repositories
Go to Cloud Source (https://source.cloud.google.com/repos) 
1. myapp1-app-repo -> Settings -> Delete this repository
2. myapp1-k8s-repo -> Settings -> Delete this repository

# Delete Kubernetes Deployment
kubect get deploy
kubectl delete deploy myapp1-deployment

# Delete Kubernetes Service
kubectl get svc
kubectl delete svc myapp1-lb-service 

# Delete Artifact Registry
Go to Artifact Registry -> Repositories -> myapps-repository -> DELETE

# Delete Local Repos
cd course-repos
rm -rf myapp1-app-repo
rm -rf myapp1-k8s-repo
```

## References
- https://github.com/GoogleCloudPlatform/gke-gitops-tutorial-cloudbuild
