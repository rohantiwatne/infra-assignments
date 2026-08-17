# Architecture

## Goals

- reproducible local environment
- thin HTTP handlers
- explicit service/repository boundaries
- Kubernetes-native health signaling
- separated infrastructure and application deployment concerns
- minimal dependencies

## Components

### Go service

Layers:

```text
HTTP Handler
   |
Service
   |
Repository
   |
PostgreSQL
```

The handler owns HTTP concerns only. The service owns business rules/validation. The repository owns persistence.

### PostgreSQL

A StatefulSet with a PVC provides stable identity and local persistence.

### Terraform

Terraform provisions the infrastructure foundation:

- namespace
- PVC
- PostgreSQL StatefulSet
- PostgreSQL Service
- database Secret

### Kustomize

Kustomize owns the application deployment:

- ConfigMap
- migration Job
- Deployment
- Service

The separation is deliberate: Terraform manages infrastructure, while Kustomize manages application rollout artifacts.

## Request flow

```text
Client
  |
  v
config-service Service
  |
  v
HTTP Handler
  |
  v
Config Service
  |
  v
Config Repository
  |
  v
PostgreSQL
```

## Readiness flow

```text
Kubernetes
   |
   +--> GET /ping
   |      |
   |      +--> process alive
   |
   +--> GET /readyz
          |
          +--> SELECT 1
                  |
                  +--> DB reachable -> Ready
                  +--> DB unavailable -> Not Ready
```

## Tradeoffs

### Why Minikube?

It provides a simple single-node local Kubernetes experience and an uncomplicated image workflow.

### Why PostgreSQL inside Kubernetes?

It makes the assignment reproducible without depending on a specific host installation.

### Why Kustomize instead of Helm?

The workload is small and has no meaningful template complexity. Kustomize keeps YAML explicit and avoids introducing chart lifecycle concepts unnecessarily.

### Why not run migrations from application startup?

Schema management is an operational concern and should not be tightly coupled to application startup. A dedicated migration Job makes the workflow visible and repeatable.

### Why not use Terraform for every Kubernetes object?

Application rollout is clearer when handled by Kubernetes-native manifests/Kustomize. Terraform remains focused on infrastructure.
