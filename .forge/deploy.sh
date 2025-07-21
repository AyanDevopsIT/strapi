#!/bin/bash

# REQUIRES: aws

set -e

echo "Starting Strapi AWS infrastructure deployment..."

terraform -chdir=infra init
terraform -chdir=infra plan -out=tfplan
terraform -chdir=infra apply -auto-approve tfplan

echo "Infrastructure deployed successfully."

# OUTPUT CREDENTIALS

EC2_PUBLIC_IP=$(terraform -chdir=infra output -raw ec2_public_ip)
STRAPI_URL=$(terraform -chdir=infra output -raw strapi_url)
RDS_ENDPOINT=$(terraform -chdir=infra output -raw rds_endpoint)
S3_BUCKET=$(terraform -chdir=infra output -raw s3_bucket_name)

echo "STRAPI_URL=http://$EC2_PUBLIC_IP:1337"
echo "EC2_PUBLIC_IP=$EC2_PUBLIC_IP"
echo "RDS_ENDPOINT=$RDS_ENDPOINT"
echo "S3_BUCKET_NAME=$S3_BUCKET"