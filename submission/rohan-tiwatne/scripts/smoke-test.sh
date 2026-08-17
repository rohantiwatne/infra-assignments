#!/usr/bin/env bash
set -euo pipefail

NAMESPACE="config-service"
LOCAL_PORT="${LOCAL_PORT:-8080}"
PF_PID=""

cleanup() {
  if [[ -n "${PF_PID}" ]] && kill -0 "${PF_PID}" >/dev/null 2>&1; then
    kill "${PF_PID}" >/dev/null 2>&1 || true
  fi
}
trap cleanup EXIT

kubectl -n "${NAMESPACE}" rollout status deployment/config-service --timeout=120s

kubectl -n "${NAMESPACE}" port-forward svc/config-service "${LOCAL_PORT}:8080" >/tmp/config-service-port-forward.log 2>&1 &
PF_PID=$!

for _ in {1..30}; do
  if curl -fsS "http://localhost:${LOCAL_PORT}/ping" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

echo "Checking /ping"
PING="$(curl -fsS "http://localhost:${LOCAL_PORT}/ping")"
[[ "${PING}" == "pong" ]]

echo "Checking /readyz"
curl -fsS "http://localhost:${LOCAL_PORT}/readyz" >/dev/null

echo "Creating config"
curl -fsS \
  -X POST \
  -H 'Content-Type: application/json' \
  -d '{"id":"cfg_smoke","host":"localhost","port":8080,"app_name":"config-service","log_level":"INFO"}' \
  "http://localhost:${LOCAL_PORT}/configs" >/dev/null

echo "Retrieving config"
BODY="$(curl -fsS "http://localhost:${LOCAL_PORT}/configs/cfg_smoke")"
echo "${BODY}" | grep -q '"id":"cfg_smoke"'

echo "Checking 404"
HTTP_CODE="$(curl -s -o /tmp/config-service-404.json -w '%{http_code}' "http://localhost:${LOCAL_PORT}/configs/does-not-exist")"
[[ "${HTTP_CODE}" == "404" ]]

echo "Smoke tests passed."
