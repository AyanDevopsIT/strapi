#!/bin/bash

set -e

echo "Destroying Strapi AWS infrastructure..."

terraform -chdir=infra destroy -auto-approve

echo "Strapi infrastructure destroyed successfully."