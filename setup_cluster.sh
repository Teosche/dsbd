#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

CLUSTER_NAME="dsbd-cluster"

echo "🚀 Starting Kubernetes Setup for DSBD Project..."

# 1. Check/Create Kind Cluster with Ingress support
if kind get clusters | grep -q "^$CLUSTER_NAME$"; then
    echo "✅ Cluster '$CLUSTER_NAME' already exists."
else
    echo "📦 Creating Kind cluster '$CLUSTER_NAME' with Ingress configuration..."
    cat <<EOF | kind create cluster --name "$CLUSTER_NAME" --config=-
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
- role: control-plane
  kubeadmConfigPatches:
  - | 
    kind: InitConfiguration
    nodeRegistration:
      kubeletExtraArgs:
        node-labels: "ingress-ready=true"
  extraPortMappings:
  - containerPort: 80
    hostPort: 80
    protocol: TCP
  - containerPort: 443
    hostPort: 443
    protocol: TCP
EOF
fi

# 2. Build Docker Images
echo "🔨 Building Docker images..."
docker build -t user-manager:latest ./microservices/user_manager
docker build -t data-collector:latest ./microservices/data_collector
docker build -t alert-system:latest ./microservices/alert_system
docker build -t alert-notifier-system:latest ./microservices/alert_notifier_system

# 3. Load Images into Kind
echo "🚚 Loading images into Kind cluster..."
kind load docker-image user-manager:latest --name "$CLUSTER_NAME"
kind load docker-image data-collector:latest --name "$CLUSTER_NAME"
kind load docker-image alert-system:latest --name "$CLUSTER_NAME"
kind load docker-image alert-notifier-system:latest --name "$CLUSTER_NAME"

# 4. Install NGINX Ingress Controller
echo "🌐 Installing NGINX Ingress Controller..."
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

echo "⏳ Waiting for Ingress Controller to be ready..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=180s

# 5. Apply Kubernetes Manifests
echo "📄 Applying Kubernetes manifests..."

# Secrets & Configs
kubectl apply -f kubernetes/secrets.yaml
kubectl apply -f kubernetes/prometheus-config.yaml

# Infrastructure (DBs, Kafka, Zookeeper)
kubectl apply -f kubernetes/infrastructure-deployment.yaml

echo "⏳ Waiting for Infrastructure (DBs & Kafka) to start..."
# A simple wait is safer than complex conditions for statefulsets in simple scripts
sleep 30 

# Microservices
kubectl apply -f kubernetes/user-manager-deployment.yaml
kubectl apply -f kubernetes/data-collector-deployment.yaml
kubectl apply -f kubernetes/alert-system-deployment.yaml
kubectl apply -f kubernetes/alert-notifier-system-deployment.yaml

# Monitoring
kubectl apply -f kubernetes/prometheus-deployment.yaml

# Ingress
kubectl apply -f kubernetes/ingress.yaml

echo "🎉 Setup Complete!"
echo "------------------------------------------------"
echo "👉 Services are exposed on localhost via Ingress."
echo "   Test User Manager: curl localhost/user-manager/ping"
echo "   Test Data Collector: curl localhost/data-collector/ping"
echo "👉 Prometheus is available via NodePort or Port-Forwarding."
echo "   Access Prometheus: kubectl port-forward svc/prometheus 9090:9090"
echo "------------------------------------------------"
