#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="config-service"

echo "Removing old migration job if present..."
kubectl -n "${NAMESPACE}" delete job/config-service-migration --ignore-not-found=true

echo "Applying application resources..."
kubectl apply -k k8s/overlays/local

echo "Waiting for PostgreSQL..."
kubectl -n "${NAMESPACE}" rollout status statefulset/postgres --timeout=180s

echo "Waiting for migration..."
kubectl -n "${NAMESPACE}" wait --for=condition=complete job/config-service-migration --timeout=180s

echo "Waiting for application rollout..."
kubectl -n "${NAMESPACE}" rollout status deployment/config-service --timeout=180s

echo "Deployment complete."
