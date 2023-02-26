---
title: GCP Google Kubernetes Engine GKE External DNS Install
description: Implement GCP Google Kubernetes Engine GKE External DNS Install
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
1. Create GCP IAM Service Account: external-dns-gsa
2. Add IAM Roles to GCP IAM Service Account (add-iam-policy-binding)
3. Create Kubernetes Namespace: external-dns-ns
4. Create Kubernetes Service Account: external-dns-ksa
5. Associate GCP IAM Service Account with Kubernetes Service Account (gcloud iam service-accounts add-iam-policy-binding)
6. Annotate Kubernetes Service Account with GCP IAM SA email Address (kubectl annotate serviceaccount)
7. Install Helm CLI on your local desktop (if not installed)
8. Install  External-DNS using Helm
9. Verify External-DNS Logs
10. Additional Reference: Install [ExternalDNS Controller using Helm](https://github.com/kubernetes-sigs/external-dns)

## Step-03: Create GCP IAM Service Account
```t
# List IAM Service Accounts
gcloud iam service-accounts list

# Create GCP IAM Service Account
gcloud iam service-accounts create GSA_NAME --project=GSA_PROJECT
GSA_NAME: the name of the new IAM service account.
GSA_PROJECT: the project ID of the Google Cloud project for your IAM service account.

# Replace GSA_NAME and GSA_PROJECT
gcloud iam service-accounts create external-dns-gsa --project=kdaida123

# List IAM Service Accounts
gcloud iam service-accounts list
```

## Step-04: Add IAM Roles to GCP IAM Service Account
```t
# Add IAM Roles to GCP IAM Service Account
gcloud projects add-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:GSA_NAME@GSA_PROJECT.iam.gserviceaccount.com" \
    --role "ROLE_NAME"
PROJECT_ID: your Google Cloud project ID.
GSA_NAME: the name of your IAM service account.
GSA_PROJECT: the project ID of the Google Cloud project of your IAM service account.
ROLE_NAME: the IAM role to assign to your service account, like roles/spanner.viewer.

# Replace PROJECT_ID, GSA_NAME, GSA_PROJECT, ROLE_NAME
gcloud projects add-iam-policy-binding kdaida123 \
    --member "serviceAccount:external-dns-gsa@kdaida123.iam.gserviceaccount.com" \
    --role "roles/dns.admin" 
```

## Step-05: Create Kubernetes Namepsace and Kubernetes Service Account
```t
# Create Kubernetes Namespace
kubectl create namespace <NAMESPACE>
kubectl create namespace external-dns-ns

# List Namespaces
kubectl get ns

# Create Service Account
kubectl create serviceaccount <KSA_NAME>  --namespace <NAMESPACE>
kubectl create serviceaccount external-dns-ksa  --namespace external-dns-ns

# List Service Accounts
kubectl -n external-dns-ns get sa
```

## Step-06: Associate GCP IAM Service Account with Kubernetes Service Account
- Allow the Kubernetes service account to impersonate the IAM service account by adding an IAM policy binding between the two service accounts.
- This binding allows the Kubernetes service account to act as the IAM service account.
```t
# Associate GCP IAM Service Account with Kubernetes Service Account
gcloud iam service-accounts add-iam-policy-binding GSA_NAME@GSA_PROJECT.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:PROJECT_ID.svc.id.goog[NAMESPACE/KSA_NAME]"

# Replace GSA_NAME, GSA_PROJECT, PROJECT_ID, NAMESPACE, KSA_NAME
gcloud iam service-accounts add-iam-policy-binding external-dns-gsa@kdaida123.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:kdaida123.svc.id.goog[external-dns-ns/external-dns-ksa]"
```

## Step-07: Annotate Kubernetes Service Account with GCP IAM SA email Address
- Annotate the Kubernetes service account with the email address of the IAM service account.
```t
# Annotate Kubernetes Service Account with GCP IAM SA email Address
kubectl annotate serviceaccount KSA_NAME \
    --namespace NAMESPACE \
    iam.gke.io/gcp-service-account=GSA_NAME@GSA_PROJECT.iam.gserviceaccount.com

# Replace KSA_NAME, NAMESPACE, GSA_NAME, GSA_PROJECT
kubectl annotate serviceaccount external-dns-ksa \
    --namespace external-dns-ns \
    iam.gke.io/gcp-service-account=external-dns-gsa@kdaida123.iam.gserviceaccount.com

# Describe Kubernetes Service Account
kubectl -n external-dns-ns describe sa external-dns-ksa 
```

## Step-08: Install Helm Client on Local Desktop
- [Install Helm](https://helm.sh/docs/intro/install/)
```t
# Install Helm
brew install helm

# Verify Helm version
helm version
```

## Step-09: Review external-dns values.yaml
- [external-dns values.yaml](https://github.com/kubernetes-sigs/external-dns/blob/master/charts/external-dns/values.yaml)
- [external-dns Configuration](https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns#configuration)


## Step-10: Review external-dns Deployment Configs
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: external-dns
rules:
- apiGroups: [""]
  resources: ["services","endpoints","pods"]
  verbs: ["get","watch","list"]
- apiGroups: ["extensions","networking.k8s.io"]
  resources: ["ingresses"] 
  verbs: ["get","watch","list"]
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: external-dns-viewer
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: external-dns
subjects:
- kind: ServiceAccount
  name: external-dns
  namespace: default
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
spec:
  strategy:
    type: Recreate
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: k8s.gcr.io/external-dns/external-dns:v0.8.0
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=external-dns-test.gcp.zalan.do # will make ExternalDNS see only the hosted zones matching provided domain, omit to process all available hosted zones
        - --provider=google
#        - --google-project=zalando-external-dns-test # Use this to specify a project different from the one external-dns is running inside
        - --google-zone-visibility=private # Use this to filter to only zones with this visibility. Set to either 'public' or 'private'. Omitting will match public and private zones
        - --policy=upsert-only # would prevent ExternalDNS from deleting any records, omit to enable full synchronization
        - --registry=txt
        - --txt-owner-id=my-identifier
```

## Step-11: Install external-dns using Helm
```t
# Add external-dns repo to Helm
helm repo add external-dns https://kubernetes-sigs.github.io/external-dns/

# Install Helm Chart
helm upgrade --install external-dns external-dns/external-dns \
    --set provider=google \
    --set policy=sync \
    --set google-zone-visibility=public \
    --set txt-owner-id=k8s \
    --set serviceAccount.create=false \
    --set serviceAccount.name=external-dns-ksa \
    -n external-dns-ns
    
# Optional Setting (Important Note: will make ExternalDNS see only the Cloud DNS zones matching provided domain, omit to process all available Cloud DNS zones)
--set domain-filter=kalyanreddydaida.com \
```

## Step-12: Verify external-dns deployment
```t
# List Helm 
helm  list -n external-dns-ns

# List Kubernetes Service Account
kubectl -n external-dns-ns get sa

# Describe Kubernetes Service Account
kubectl -n external-dns-ns describe sa external-dns-ksa

# List All resources from default Namespace
kubectl -n external-dns-ns get all

# List pods (external-dns pod should be in running state)
kubectl -n external-dns-ns get pods

# Verify Deployment by checking logs
kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
[or]
kubectl -n external-dns-ns get pods
kubectl -n external-dns-ns logs -f <External-DNS-Pod-Name>
```

## References
- https://github.com/kubernetes-sigs/external-dns/tree/master/charts/external-dns
- https://github.com/kubernetes-sigs/external-dns/blob/master/docs/tutorials/gke.md

## External-DNS Logs from Reference

```log
W0624 07:14:15.829747   14199 gcp.go:120] WARNING: the gcp auth plugin is deprecated in v1.22+, unavailable in v1.25+; use gcloud instead.
To learn more, consult https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
Error from server (BadRequest): container "external-dns" in pod "external-dns-6f49549d96-2jd5q" is waiting to start: ContainerCreating
Kalyans-Mac-mini:48-GKE-Ingress-IAP kalyanreddy$ kubectl -n external-dns-ns logs -f $(kubectl -n external-dns-ns get po | egrep -o 'external-dns[A-Za-z0-9-]+')
W0624 07:14:23.520269   14201 gcp.go:120] WARNING: the gcp auth plugin is deprecated in v1.22+, unavailable in v1.25+; use gcloud instead.
To learn more, consult https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
W0624 07:14:24.512312   14203 gcp.go:120] WARNING: the gcp auth plugin is deprecated in v1.22+, unavailable in v1.25+; use gcloud instead.
To learn more, consult https://cloud.google.com/blog/products/containers-kubernetes/kubectl-auth-changes-in-gke
time="2022-06-24T01:44:18Z" level=info msg="config: {APIServerURL: KubeConfig: RequestTimeout:30s DefaultTargets:[] ContourLoadBalancerService:heptio-contour/contour GlooNamespace:gloo-system SkipperRouteGroupVersion:zalando.org/v1 Sources:[service ingress] Namespace: AnnotationFilter: LabelFilter: FQDNTemplate: CombineFQDNAndAnnotation:false IgnoreHostnameAnnotation:false IgnoreIngressTLSSpec:false IgnoreIngressRulesSpec:false Compatibility: PublishInternal:false PublishHostIP:false AlwaysPublishNotReadyAddresses:false ConnectorSourceServer:localhost:8080 Provider:google GoogleProject: GoogleBatchChangeSize:1000 GoogleBatchChangeInterval:1s GoogleZoneVisibility: DomainFilter:[] ExcludeDomains:[] RegexDomainFilter: RegexDomainExclusion: ZoneNameFilter:[] ZoneIDFilter:[] AlibabaCloudConfigFile:/etc/kubernetes/alibaba-cloud.json AlibabaCloudZoneType: AWSZoneType: AWSZoneTagFilter:[] AWSAssumeRole: AWSBatchChangeSize:1000 AWSBatchChangeInterval:1s AWSEvaluateTargetHealth:true AWSAPIRetries:3 AWSPreferCNAME:false AWSZoneCacheDuration:0s AWSSDServiceCleanup:false AzureConfigFile:/etc/kubernetes/azure.json AzureResourceGroup: AzureSubscriptionID: AzureUserAssignedIdentityClientID: BluecatDNSConfiguration: BluecatConfigFile:/etc/kubernetes/bluecat.json BluecatDNSView: BluecatGatewayHost: BluecatRootZone: BluecatDNSServerName: BluecatDNSDeployType:no-deploy BluecatSkipTLSVerify:false CloudflareProxied:false CloudflareZonesPerPage:50 CoreDNSPrefix:/skydns/ RcodezeroTXTEncrypt:false AkamaiServiceConsumerDomain: AkamaiClientToken: AkamaiClientSecret: AkamaiAccessToken: AkamaiEdgercPath: AkamaiEdgercSection: InfobloxGridHost: InfobloxWapiPort:443 InfobloxWapiUsername:admin InfobloxWapiPassword: InfobloxWapiVersion:2.3.1 InfobloxSSLVerify:true InfobloxView: InfobloxMaxResults:0 InfobloxFQDNRegEx: InfobloxCreatePTR:false InfobloxCacheDuration:0 DynCustomerName: DynUsername: DynPassword: DynMinTTLSeconds:0 OCIConfigFile:/etc/kubernetes/oci.yaml InMemoryZones:[] OVHEndpoint:ovh-eu OVHApiRateLimit:20 PDNSServer:http://localhost:8081 PDNSAPIKey: PDNSTLSEnabled:false TLSCA: TLSClientCert: TLSClientCertKey: Policy:sync Registry:txt TXTOwnerID:default TXTPrefix: TXTSuffix: Interval:1m0s MinEventSyncInterval:5s Once:false DryRun:false UpdateEvents:false LogFormat:text MetricsAddress::7979 LogLevel:info TXTCacheInterval:0s TXTWildcardReplacement: ExoscaleEndpoint:https://api.exoscale.ch/dns ExoscaleAPIKey: ExoscaleAPISecret: CRDSourceAPIVersion:externaldns.k8s.io/v1alpha1 CRDSourceKind:DNSEndpoint ServiceTypeFilter:[] CFAPIEndpoint: CFUsername: CFPassword: RFC2136Host: RFC2136Port:0 RFC2136Zone: RFC2136Insecure:false RFC2136GSSTSIG:false RFC2136KerberosRealm: RFC2136KerberosUsername: RFC2136KerberosPassword: RFC2136TSIGKeyName: RFC2136TSIGSecret: RFC2136TSIGSecretAlg: RFC2136TAXFR:false RFC2136MinTTL:0s RFC2136BatchChangeSize:50 NS1Endpoint: NS1IgnoreSSL:false NS1MinTTLSeconds:0 TransIPAccountName: TransIPPrivateKeyFile: DigitalOceanAPIPageSize:50 ManagedDNSRecordTypes:[A CNAME] GoDaddyAPIKey: GoDaddySecretKey: GoDaddyTTL:0 GoDaddyOTE:false OCPRouterName:}"
time="2022-06-24T01:44:18Z" level=info msg="Instantiating new Kubernetes client"
time="2022-06-24T01:44:18Z" level=info msg="Using inCluster-config based on serviceaccount-token"
time="2022-06-24T01:44:18Z" level=info msg="Created Kubernetes client https://10.104.0.1:443"
time="2022-06-24T01:44:18Z" level=info msg="Google project auto-detected: kdaida123"
time="2022-06-24T01:44:23Z" level=error msg="Get \"https://dns.googleapis.com/dns/v1/projects/kdaida123/managedZones?alt=json&prettyPrint=false\": compute: Received 403 `Unable to generate access token; IAM returned 403 Forbidden: The caller does not have permission\nThis error could be caused by a missing IAM policy binding on the target IAM service account.\nFor more information, refer to the Workload Identity documentation:\n\thttps://cloud.google.com/kubernetes-engine/docs/how-to/workload-identity#authenticating_to\n\n`"

```