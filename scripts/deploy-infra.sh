#!/bin/bash

set -e
source "$(dirname "$0")/config.sh"



echo "Checking backend S3 bucket..."
if ! aws s3 ls "s3://$TF_STATE_BUCKET_NAME" --region "$TF_STATE_BUCKET_REGION" >/dev/null 2>&1; then
  echo "Creating backend bucket..."
  aws s3 mb "s3://$TF_STATE_BUCKET_NAME" --region "$TF_STATE_BUCKET_REGION"
  aws s3api put-bucket-versioning --bucket "$TF_STATE_BUCKET_NAME" --versioning-configuration Status=Enabled --region "$TF_STATE_BUCKET_REGION"
fi


# 1. Terraform
terraform -chdir="terraform" init -reconfigure -upgrade \
    -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
    -backend-config="key=EKS-project/terraform.tfstate" \
    -backend-config="region=$TF_STATE_BUCKET_REGION"

terraform -chdir="terraform" apply \
    -var aws_region=$AWS_REGION \
    -var cluster_name=$CLUSTER_NAME \
    -var-file="terraform.tfvars" \
    --auto-approve

# 2. Configure kubectl
aws eks update-kubeconfig \
  --region $AWS_REGION \
  --name $CLUSTER_NAME

# 3. Configure RBAC
kubectl apply -f k8s/bootstrap/aws-auth.yaml
kubectl apply -f k8s/bootstrap/namespace.yaml
kubectl apply -f k8s/rbac/app-role.yaml
kubectl apply -f k8s/rbac/monitoring-cluster-role.yaml
kubectl apply -f k8s/rbac/rolebinding.yaml

# 4. Verify
kubectl get nodes