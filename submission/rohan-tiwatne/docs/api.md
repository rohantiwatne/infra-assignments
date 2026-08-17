# API Contract

## GET /ping

Purpose: process liveness.

Response:

```text
pong
```

Status: `200 OK`

## GET /readyz

Purpose: application readiness.

The service performs a lightweight database connectivity check.

Ready:

```json
{"status":"ready"}
```

Status: `200 OK`

Not ready:

```json
{"status":"not_ready"}
```

Status: `503 Service Unavailable`

## GET /configs/:id

`:id` is the stable configuration identifier.

Success:

- `200 OK`

Missing:

- `404 Not Found`

Invalid/empty identifiers:

- `400 Bad Request`

Error response:

```json
{
  "error": "config not found"
}
```

## POST /configs

Creates or updates a config by ID.

The operation is idempotent for the same identifier and current field values.

Validation:

- `id` required
- `host` required
- `port` must be between `1` and `65535`
- `app_name` required
- `log_level` required

Status:

- `200 OK` for successful upsert
- `400 Bad Request` for malformed/invalid payload
- `500 Internal Server Error` for unexpected persistence failure

Example request:

```json
{
  "id": "cfg_1",
  "host": "localhost",
  "port": 8080,
  "app_name": "config-service",
  "log_level": "INFO"
}
```

Example response:

```json
{
  "id": "cfg_1",
  "host": "localhost",
  "port": 8080,
  "app_name": "config-service",
  "log_level": "INFO"
}
```
