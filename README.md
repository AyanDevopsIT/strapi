# Strapi AWS Infrastructure Stack

## Overview

This stack deploys **Strapi** on AWS using Terraform. It provisions:
- VPC with 2 public subnets
- EC2 instance running Strapi via Docker
- Postgres RDS database
- S3 bucket for media uploads

## Required Integrations

- AWS (`# REQUIRES: aws`)

## How to Deploy

```bash
chmod +x .forge/deploy.sh
.forge/deploy.sh