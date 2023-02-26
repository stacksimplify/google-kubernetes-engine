apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp1-deployment
  labels:
    app: myapp1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp1
  template:
    metadata:
      labels:
        app: myapp1
    spec:
      containers:
      - name: myapp1
        image: us-central1-docker.pkg.dev/GOOGLE_CLOUD_PROJECT/myapps-repository/myapp1:COMMIT_SHA
        ports:
        - containerPort: 80
---
kind: Service
apiVersion: v1
metadata:
  name: myapp1-lb-service
spec:
  type: LoadBalancer
  selector:
    app: myapp1
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
