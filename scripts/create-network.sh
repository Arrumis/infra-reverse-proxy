#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.local}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

NETWORK_NAME="${PROXY_NETWORK_NAME:-proxy-network}"

if docker network inspect "${NETWORK_NAME}" >/dev/null 2>&1; then
  echo "Network already exists: ${NETWORK_NAME}"
else
  docker network create "${NETWORK_NAME}"
  echo "Created network: ${NETWORK_NAME}"
fi

