


# 1. Configure kubectl
aws eks update-kubeconfig \
  --region $AWS_REGION \
  --name $CLUSTER_NAME

# 2. Perform kubectl
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/ingress.yaml

