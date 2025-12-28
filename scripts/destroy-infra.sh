#!/bin/bash

set -e
source "$(dirname "$0")/config.sh"


# 1. Terraform
terraform -chdir="terraform" init -reconfigure -upgrade \
    -backend-config="bucket=$TF_STATE_BUCKET_NAME" \
    -backend-config="key=EKS-project/terraform.tfstate" \
    -backend-config="region=$TF_STATE_BUCKET_REGION"

terraform -chdir="terraform" destroy \
    -var aws_region=$AWS_REGION \
    -var cluster_name=$CLUSTER_NAME \
    -var-file="terraform.tfvars" \
    --auto-approve

