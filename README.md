Strapi Terraform Deployment

This repository deploys a complete Strapi application stack on AWS using Terraform.
It provisions a VPC with public subnets and an internet gateway, an EC2 Ubuntu instance configured with Docker and Docker Compose to run Strapi, and an RDS PostgreSQL database for persistent storage. Security groups are created to allow SSH on port 22, Strapi access on port 1337, and restrict Postgres access only to the Strapi instance. An optional S3 bucket can also be created for storing media files.

Forge integrates with this deployment through two scripts:
	•	.forge/deploy.sh initializes Terraform, applies the plan, and outputs the Strapi URL, EC2 public IP, and optional Grafana details in Forge-compatible format.
	•	.forge/destroy.sh cleans up by destroying all deployed AWS resources.
    
    When finished, remove everything by running .forge/destroy.sh.