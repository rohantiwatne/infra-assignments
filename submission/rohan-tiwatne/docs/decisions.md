# Architecture Decisions

## ADR-001: PostgreSQL runs inside Kubernetes

### Decision

Run PostgreSQL as a StatefulSet with PVC-backed local storage.

### Reason

The entire environment becomes reproducible without relying on a developer's host database.

### Consequence

This is appropriate for a local assignment but is not a production-grade HA database topology.

## ADR-002: Kustomize for application deployment

### Decision

Use Kustomize rather than Helm.

### Reason

The service has low deployment parameter complexity and transparent YAML is easier to inspect during review.

## ADR-003: Dedicated migration Job

### Decision

Run the schema migration as a Kubernetes Job.

### Reason

Separates deployment from schema management and makes migration status visible.

## ADR-004: Readiness checks PostgreSQL

### Decision

`/readyz` checks database connectivity.

### Reason

A process can be alive but unable to serve the application's core function.

## ADR-005: Terraform for infrastructure foundation

### Decision

Terraform manages the local infrastructure layer rather than every application object.

### Reason

This keeps ownership clear and avoids mixing application rollout mechanics with infrastructure state.
