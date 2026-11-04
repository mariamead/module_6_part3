#!/usr/bin/env bash
set -euo pipefail

minikube start --driver=docker

#  ADDED FOR APPROACH 2: Enable the native ingress addon automatically
#minikube addons enable ingress
minikube status

# You cannot run chmod +x inside the script on itself to make it 
# executable. You must run that command once in your regular terminal 
# before you run the script for the first time.
#chmod +x apply_minikube_dockerenv.sh


# Force builds into Minikube's Docker daemon (Docker driver)
eval "$(minikube -p minikube docker-env)"

IMAGES=("backend:latest" "transactions:latest" "studentportfolio:latest")

for img in "${IMAGES[@]}"; do
  name="${img%%:*}"
  echo ">> docker build -t ${img} ./${name}"
  docker build -t "${img}" "./${name}"
done

echo "==> Verify images inside the node's Docker:"
minikube ssh -- docker images | egrep 'backend|transactions|studentportfolio' || true

echo "==> Apply manifests"
kubectl apply -f k8s/

echo "==> Restart deployments to pick up local images"
kubectl rollout restart deploy backend transactions studentportfolio

echo
echo "Open the app:"
echo "  minikube service nginx"
echo "or http://$(minikube ip):30080"
#  OR UPDATED FOR APPROACH 2: No more port 30080 needed!
#echo "  http://$(minikube ip)/" 
