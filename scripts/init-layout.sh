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
touch .htpasswd
./scripts/render-configs.sh http

echo "Initialized reverse proxy layout."
