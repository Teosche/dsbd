#!/bin/bash

set -euo

# We use minikube to provide a complete local k8s cluster and an integrated Docker daemon.
# Then we can build images and use them immediately in the cluster without having to push them to a registry.

# brew install minikube

# or just use dpkg for Debian systems:
# https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fdebian+package
if ! minikube status >/dev/null 2>&1; then
    minikube start
else
    echo "[!] minikube already started."
fi

eval $(minikube docker-env)

echo "[+] building Docker images..."
docker build -t user-manager:latest ./microservices/user_manager
docker build -t data-collector:latest ./microservices/data_collector

echo "[+] applying Kubernetes manifests..."
kubectl apply -f kubernetes/

echo "[!] waiting for deployments to be ready..."
kubectl rollout status deployment/prometheus
kubectl rollout status deployment/user-manager
kubectl rollout status deployment/data-collector

echo "Deployment complete!"

PROM_URL=$(minikube service prometheus --url)
USER_MANAGER_PORT=$(kubectl get svc user-manager -o jsonpath='{.spec.ports[0].nodePort}')
MINIKUBE_IP=$(minikube ip)

echo ""
echo "Prometheus UI: $PROM_URL"
echo "User Manager metrics -> http://$MINIKUBE_IP:$USER_MANAGER_PORT/metrics"
echo ""
