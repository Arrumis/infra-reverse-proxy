#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.local}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

mkdir -p data/conf.d data/html data/letsencrypt data/log data/log_letsencrypt templates

cp templates/nginx.conf nginx.conf
cp templates/logformat.conf data/conf.d/logformat.conf

if command -v envsubst >/dev/null 2>&1; then
  DOMAIN="${DOMAIN:-example.local}" envsubst '${DOMAIN}' < templates/first.conf > data/conf.d/default.conf
else
  cp templates/first.conf data/conf.d/default.conf
fi

touch .htpasswd

echo "Initialized reverse proxy layout."

