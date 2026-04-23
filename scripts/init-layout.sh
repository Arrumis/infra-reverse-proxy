#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.local}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

mkdir -p data/traefik/dynamic data/letsencrypt data/log

if [[ ! -f data/letsencrypt/acme.json ]]; then
  touch data/letsencrypt/acme.json
fi

chmod 600 data/letsencrypt/acme.json

BASIC_AUTH_USER="${BASIC_AUTH_USER:-admin}"
BASIC_AUTH_PASSWORD="${BASIC_AUTH_PASSWORD:-change-me}"

if command -v openssl >/dev/null 2>&1; then
  printf '%s:%s\n' \
    "${BASIC_AUTH_USER}" \
    "$(openssl passwd -apr1 "${BASIC_AUTH_PASSWORD}")" > .htpasswd
  chmod 600 .htpasswd
else
  echo "openssl is required to generate .htpasswd" >&2
  exit 1
fi

./scripts/render-configs.sh
echo "Initialized Traefik reverse proxy layout."
