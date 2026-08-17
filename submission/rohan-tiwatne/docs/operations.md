# Operations

## Start

```bash
make bootstrap
make all
```

## Health

```bash
make validate
```

## Logs

```bash
make logs
```

## Inspect pods

```bash
kubectl -n config-service get pods -o wide
```

## Inspect rollout

```bash
kubectl -n config-service rollout status deployment/config-service
```

## Database

```bash
kubectl -n config-service get statefulset
kubectl -n config-service get pvc
kubectl -n config-service logs statefulset/postgres
```

## Restart application

```bash
kubectl -n config-service rollout restart deployment/config-service
kubectl -n config-service rollout status deployment/config-service
```

## Common failures

### Application is not ready

Check:

```bash
kubectl -n config-service describe pod -l app=config-service
kubectl -n config-service logs deployment/config-service
```

### PostgreSQL is not ready

Check:

```bash
kubectl -n config-service get pods
kubectl -n config-service describe pod -l app=postgres
kubectl -n config-service logs statefulset/postgres
```

### Migration failed

Check:

```bash
kubectl -n config-service get jobs
kubectl -n config-service logs job/config-service-migration
```

## Local secret handling

Never commit:

```text
infra/terraform/terraform.tfvars
```

For production, use an external secret manager and short-lived credentials where practical.
