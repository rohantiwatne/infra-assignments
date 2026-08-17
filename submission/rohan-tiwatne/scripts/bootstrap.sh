#!/usr/bin/env bash
set -euo pipefail

command -v minikube >/dev/null || { echo "minikube is required"; exit 1; }
command -v kubectl >/dev/null || { echo "kubectl is required"; exit 1; }
command -v docker >/dev/null || { echo "docker is required"; exit 1; }
command -v terraform >/dev/null || { echo "terraform is required"; exit 1; }

if ! minikube status >/dev/null 2>&1; then
  minikube start --driver=docker
fi

kubectl config use-context minikube >/dev/null

TFVARS="infra/terraform/terraform.tfvars"
if [[ ! -f "${TFVARS}" ]]; then
  cat > "${TFVARS}" <<'EOF'
db_name     = "configdb"
db_user     = "configuser"
db_password = "local-dev-password"
db_storage  = "1Gi"
EOF
  echo "Created ${TFVARS} for local development."
fi

echo "Bootstrap complete."
