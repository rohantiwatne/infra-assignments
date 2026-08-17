# Kubernetes Config Service

## Infrastructure design

- **Cluster:** Minikube with Docker driver.
- **Database:** PostgreSQL 16 in a Kubernetes StatefulSet with PVC-backed storage.
- **IaC:** Terraform provisions namespace, PostgreSQL StatefulSet/Service, storage, and database Secret.
- **Application deployment:** Kustomize manages the Go application Deployment, Service, ConfigMap, and migration Job.
- **Networking:** Application is a ClusterIP service. Local testing uses `kubectl port-forward`.

## Configuration and secret handling

Non-sensitive configuration is injected through a ConfigMap. The PostgreSQL password is injected through a Kubernetes Secret.

For local use, Terraform receives the password from an untracked `terraform.tfvars` file. Terraform state therefore contains sensitive data and must be treated as sensitive.

Production changes:

- external secret manager
- encrypted/remote Terraform state
- least-privilege identities
- rotation and short-lived credentials

## Operational readiness

- `/ping` is the liveness-style endpoint.
- `/readyz` checks PostgreSQL connectivity.
- Kubernetes readiness prevents traffic to an instance that cannot access its database.
- JSON structured logs are emitted through `log/slog`.
- Deployment has CPU/memory requests and limits.
- PostgreSQL and application have probes.
- Migration is a dedicated Kubernetes Job.
- Smoke tests verify the full write/read path.

Failure assumption:

If PostgreSQL becomes unavailable, the application remains alive but becomes unready until database connectivity returns.

## Repository structure

- `app/` contains the Go service.
- `infra/terraform/` contains infrastructure code.
- `k8s/` contains application deployment manifests.
- `scripts/` contains bootstrap/deploy/validation automation.
- `docs/` contains architecture and operational documentation.

The separation makes it clear which layer owns infrastructure versus application rollout.

## Responsible AI usage

AI tools were used to accelerate scaffolding, documentation, and pattern checking. The implementation must still be personally reviewed and validated locally. The engineer should verify all generated code, run the tests, inspect Terraform/Kubernetes plans, and correct any issues found during execution.
