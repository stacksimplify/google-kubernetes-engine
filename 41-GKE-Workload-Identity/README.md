---
title: GCP Google Kubernetes Engine GKE Workload Identity
description: Implement GCP Google Kubernetes Engine GKE Workload Identity
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

## Step-01: Introduction
1. Create GCP IAM Service Account
2. Add IAM Roles to GCP IAM Service Account (add-iam-policy-binding)
3. Create Kubernetes Namespace
4. Create Kubernetes Service Account
5. Associate GCP IAM Service Account with Kubernetes Service Account (gcloud iam service-accounts add-iam-policy-binding)
6. Annotate Kubernetes Service Account with GCP IAM SA email Address (kubectl annotate serviceaccount)
7. Create a Sample App with and without Kubernetes Service Account
8. Test Workload Identity in GKE Cluster

## Step-02: Verify if Workload Identity Setting is enabled for GKE Cluster
- Go to Kubernetes Engine -> Clusters -> standard-cluster-private-1 -> DETAILS Tab
- In Security -> Workload Identity	-> SHOULD BE IN ENABLED STATE

## Step-03: Create GCP IAM Service Account
```t
# List IAM Service Accounts
gcloud iam service-accounts list

# List Google Cloud Projects
gcloud projects list
Observation: 
1. Get the PROJECT_ID for your current project
2. Replace GSA_PROJECT_ID with PROJECT_ID for your current project

# Create GCP IAM Service Account
gcloud iam service-accounts create GSA_NAME --project=GSA_PROJECT_ID
GSA_NAME: the name of the new IAM service account.
GSA_PROJECT_ID: the project ID of the Google Cloud project for your IAM service account.
GSA_PROJECT==PROJECT_ID

# Replace GSA_NAME and GSA_PROJECT
gcloud iam service-accounts create wid-gcpiam-sa --project=kdaida123

# List IAM Service Accounts
gcloud iam service-accounts list
```

## Step-04: Add IAM Roles to GCP IAM Service Account
- We are giving `"roles/compute.viewer"` permissions to IAM Service Account. 
- From Kubernetes Pod, we are going to list the compute instances.
- With the help of the `Google IAM Service account` and `Kubernetes Service Account`, access for Kubernetes Pod from GKE cluster should be successful for listing the google computing instances. 
```t
# Add IAM Roles to GCP IAM Service Account
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:GSA_NAME@GSA_PROJECT_ID.iam.gserviceaccount.com" \
    --role "ROLE_NAME"
PROJECT_ID: your Google Cloud project ID.
GSA_NAME: the name of your IAM service account.
GSA_PROJECT_ID: the project ID of the Google Cloud project of your IAM service account.
GSA_PROJECT_ID==PROJECT_ID
ROLE_NAME: the IAM role to assign to your service account, like roles/spanner.viewer.

# Replace PROJECT_ID, GSA_NAME, GSA_PROJECT_ID, ROLE_NAME
gcloud projects add-iam-policy-binding kdaida123 \
    --member "serviceAccount:wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com" \
    --role "roles/compute.viewer" 
```

## Step-05: Create Kubernetes Namepsace and Service Account
```t
# Create Kubernetes Namespace
kubectl create namespace <NAMESPACE>
kubectl create namespace wid-kns

# Create Service Account
kubectl create serviceaccount <KSA_NAME>  --namespace <NAMESPACE>
kubectl create serviceaccount wid-ksa  --namespace wid-kns
```

## Step-06: Associate GCP IAM Service Account with Kubernetes Service Account
- Allow the Kubernetes service account to impersonate the IAM service account by adding an IAM policy binding between the two service accounts.
- This binding allows the Kubernetes service account to act as the IAM service account.
```t
# Associate GCP IAM Service Account with Kubernetes Service Account
gcloud iam service-accounts add-iam-policy-binding GSA_NAME@GSA_PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:PROJECT_ID.svc.id.goog[NAMESPACE/KSA_NAME]"

# Replace GSA_NAME, GSA_PROJECT_ID, PROJECT_ID, NAMESPACE, KSA_NAME
gcloud iam service-accounts add-iam-policy-binding wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:kdaida123.svc.id.goog[wid-kns/wid-ksa]"
```

## Step-07: Annotate Kubernetes Service Account with GCP IAM SA email Address
- Annotate the Kubernetes service account with the email address of the IAM service account.
```t
# Annotate Kubernetes Service Account with GCP IAM SA email Address
kubectl annotate serviceaccount KSA_NAME \
    --namespace NAMESPACE \
    iam.gke.io/gcp-service-account=GSA_NAME@GSA_PROJECT_ID.iam.gserviceaccount.com

# Replace KSA_NAME, NAMESPACE, GSA_NAME, GSA_PROJECT_ID
kubectl annotate serviceaccount wid-ksa \
    --namespace wid-kns \
    iam.gke.io/gcp-service-account=wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com

# Describe Kubernetes Service Account
kubectl describe sa wid-ksa -n wid-kns
```

## Step-08: 01-wid-demo-pod-without-sa.yaml
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wid-demo-without-sa
  namespace: wid-kns
spec:
  containers:
  - image: google/cloud-sdk:slim
    name: wid-demo-without-sa
    command: ["sleep","infinity"]
  #serviceAccountName: wid-ksa
  nodeSelector:
    iam.gke.io/gke-metadata-server-enabled: "true"
```

## Step-09: 02-wid-demo-pod-with-sa.yaml
- **Important Note:** For Autopilot clusters, omit the nodeSelector field. Autopilot rejects this nodeSelector because all nodes use Workload Identity.
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: wid-demo-with-sa
  namespace: wid-kns
spec:
  containers:
  - image: google/cloud-sdk:slim
    name: wid-demo-with-sa
    command: ["sleep","infinity"]
  serviceAccountName: wid-ksa
  nodeSelector:
    iam.gke.io/gke-metadata-server-enabled: "true"
```

## Step-10: Deploy Kubernetes Manifests and Verify
```t
# Deploy kube-manifests
kubectl apply -f kube-manifests

# List Pods
kubectl -n wid-kns get pods 
```

## Step-11: Verify from Workload Identity without Service Account Pod
```t
# Connect to Pod
kubectl -n wid-kns exec -it wid-demo-without-sa -- /bin/bash

# Default Service Account Pod is using currently
gcloud auth list
Observation: It chose the default account

## Sample Output
root@wid-demo-without-sa:/# gcloud auth list
    Credentialed Accounts
ACTIVE  ACCOUNT
*       kdaida123.svc.id.goog

To set the active account, run:
    $ gcloud config set account `ACCOUNT`

root@wid-demo-without-sa:/# 


# List Compute Instances from workload-identity-demo pod
gcloud compute instances list

## Sample Output
root@wid-demo-without-sa:/# gcloud compute instances list
ERROR: (gcloud.compute.instances.list) Some requests did not succeed:
 - Request had invalid authentication credentials. Expected OAuth 2 access token, login cookie or other valid authentication credential. See https://developers.google.com/identity/sign-in/web/devconsole-project.

root@wid-demo-without-sa:/# 

# Exit the container terminal
exit
```

## Step-12: Verify from Workload Identity with Service Account Pod
```t
# Connect to Pod
kubectl -n wid-kns exec -it wid-demo-with-sa -- /bin/bash

# Default Service Account Pod is using currently
gcloud auth list

## Sample Output
root@wid-demo-with-sa:/# gcloud auth list
                 Credentialed Accounts
ACTIVE  ACCOUNT
*       wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com

To set the active account, run:
    $ gcloud config set account `ACCOUNT`

root@wid-demo-with-sa:/# 

# List Compute Instances from workload-identity-demo pod
gcloud compute instances list

## Sample Output
root@wid-demo-with-sa:/# gcloud compute instances list
NAME                                                 ZONE           MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP    EXTERNAL_IP  STATUS
gke-standard-cluster-priva-new-pool-2-7c9415e8-5cds  us-central1-c  g1-small      true         10.128.15.235               RUNNING
gke-standard-cluster-priva-new-pool-2-7c9415e8-5mpz  us-central1-c  g1-small      true         10.128.0.8                  RUNNING
gke-standard-cluster-priva-new-pool-2-7c9415e8-8qg6  us-central1-c  g1-small      true         10.128.0.2                  RUNNING
root@wid-demo-with-sa:/# 
```

## Step-13: Negative Usecase: Test access to Cloud DNS Record Sets
```t
# gcloud list DNS Records
gcloud dns record-sets list --zone=kalyanreddydaida-com
Observation:
1. GCP IAM Service Account "wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com" doesnt have roles assigned related to Cloud DNS so we got HTTP 403

## Sample Output
root@wid-demo-with-sa:/# gcloud dns record-sets list --zone=kalyanreddydaida-com
ERROR: (gcloud.dns.record-sets.list) HTTPError 403: Forbidden
root@wid-demo-with-sa:/# 

# Exit the container terminal
exit
```

## Step-14: Give Cloud DNS Admin Role for GCP IAM Servic Account wid-gcpiam-sa
```t
# Add IAM Roles to GCP IAM Service Account
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:GSA_NAME@GSA_PROJECT.iam.gserviceaccount.com" \
    --role "ROLE_NAME"
PROJECT_ID: your Google Cloud project ID.
GSA_NAME: the name of your IAM service account.
GSA_PROJECT: the project ID of the Google Cloud project of your IAM service account.
ROLE_NAME: the IAM role to assign to your service account, like roles/spanner.viewer.
GSA_PROJECT==PROJECT_ID

# Replace PROJECT_ID, GSA_NAME, GSA_PROJECT, ROLE_NAME
gcloud projects add-iam-policy-binding kdaida123 \
    --member "serviceAccount:wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com" \
    --role "roles/dns.admin" 
```

## Step-15: Verify from Workload Identity with Service Account Pod
```t
# Connect to Pod
kubectl -n wid-kns exec -it wid-demo-with-sa -- /bin/bash

# List Cloud DNS Record Sets
gcloud dns record-sets list --zone=kalyanreddydaida-com

### Sample Output
root@wid-demo-with-sa:/# gcloud dns record-sets list --zone=kalyanreddydaida-com
NAME                         TYPE  TTL    DATA
kalyanreddydaida.com.        NS    21600  ns-cloud-a1.googledomains.com.,ns-cloud-a2.googledomains.com.,ns-cloud-a3.googledomains.com.,ns-cloud-a4.googledomains.com.
kalyanreddydaida.com.        SOA   21600  ns-cloud-a1.googledomains.com. cloud-dns-hostmaster.google.com. 1 21600 3600 259200 300
demo1.kalyanreddydaida.com.  A     300    34.120.32.120
root@wid-demo-with-sa:/# 


# List Compute Instances from workload-identity-demo pod
gcloud compute instances list

## Sample Output
root@wid-demo-with-sa:/# gcloud compute instances list
NAME                                                 ZONE           MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP    EXTERNAL_IP  STATUS
gke-standard-cluster-priva-new-pool-2-7c9415e8-5cds  us-central1-c  g1-small      true         10.128.15.235               RUNNING
gke-standard-cluster-priva-new-pool-2-7c9415e8-5mpz  us-central1-c  g1-small      true         10.128.0.8                  RUNNING
gke-standard-cluster-priva-new-pool-2-7c9415e8-8qg6  us-central1-c  g1-small      true         10.128.0.2                  RUNNING
root@wid-demo-with-sa:/# 

# Exit the container terminal 
exit
```


## Step-16: Clean-Up Kubernetes Resources
```t
# Delete Kubernetes Pods
kubectl delete -f kube-manifests

# List Namespaces
kubectl get ns

# Delete Kubernetes Namespace 
kubectl delete ns wid-kns
Observation:
1. Kubernetes Service Account "wid-ksa" will get automatically deleted when that namespace is deleted
```

## Step-17: Clean-Up GCP IAM Resources
```t
# List GCP IAM Service Accounts
gcloud iam service-accounts list

# Remove IAM Roles to GCP IAM Service Account
gcloud projects remove-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:GSA_NAME@GSA_PROJECT_ID.iam.gserviceaccount.com" \
    --role "ROLE_NAME"
PROJECT_ID: your Google Cloud project ID.
GSA_NAME: the name of your IAM service account.
GSA_PROJECT_ID: the project ID of the Google Cloud project of your IAM service account.
GSA_PROJECT_ID==PROJECT_ID
ROLE_NAME: the IAM role to assign to your service account, like roles/spanner.viewer.

# REMOVE ROLE: COMPUTE VIEWER: Replace PROJECT_ID, GSA_NAME, GSA_PROJECT, ROLE_NAME
gcloud projects remove-iam-policy-binding kdaida123 \
    --member "serviceAccount:wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com" \
    --role "roles/compute.viewer" 

# REMOVE ROLE: DNS ADMIN: Replace PROJECT_ID, GSA_NAME, GSA_PROJECT, ROLE_NAME
gcloud projects remove-iam-policy-binding kdaida123 \
    --member "serviceAccount:wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com" \
    --role "roles/dns.admin" 

# Delete the GCP IAM Service Account we have created
gcloud iam service-accounts delete wid-gcpiam-sa@kdaida123.iam.gserviceaccount.com --project=kdaida123
```

## References
- [GKE - Use Workload Identity](https://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity)