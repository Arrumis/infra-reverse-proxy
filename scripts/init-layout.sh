#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.local}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

ROOT_HOST="${ROOT_HOST:-${DOMAIN:-example.local}}"
TLS_CERT_NAME="${TLS_CERT_NAME:-${ROOT_HOST}}"
CERT_DIR="data/letsencrypt/live/${TLS_CERT_NAME}"
RENEWAL_CONF="data/letsencrypt/renewal/${TLS_CERT_NAME}.conf"

mkdir -p data/conf.d data/html data/letsencrypt data/log data/log_letsencrypt templates

cp templates/nginx.conf nginx.conf
touch .htpasswd

if compgen -G "data/letsencrypt/renewal/*.conf" >/dev/null || compgen -G "data/letsencrypt/live/*/fullchain.pem" >/dev/null; then
  ./scripts/render-configs.sh https
  echo "Initialized reverse proxy layout with existing HTTPS certificates."
else
  ./scripts/render-configs.sh http
  echo "Initialized reverse proxy layout in HTTP mode."
fi
