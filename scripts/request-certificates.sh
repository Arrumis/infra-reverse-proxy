#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.local}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

DOMAIN="${DOMAIN:-example.local}"
ROOT_HOST="${ROOT_HOST:-${DOMAIN}}"
TTRSS_HOST="${TTRSS_HOST:-ttrss.${DOMAIN}}"
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-admin@${DOMAIN}}"

./scripts/render-configs.sh http
docker compose --env-file "${ENV_FILE}" up -d

docker compose --env-file "${ENV_FILE}" run --rm --entrypoint certbot certbot certonly \
  --webroot -w /usr/share/nginx/html \
  --agree-tos \
  --email "${LETSENCRYPT_EMAIL}" \
  --non-interactive \
  -d "${ROOT_HOST}" \
  -d "${TTRSS_HOST}"

./scripts/render-configs.sh https
docker compose --env-file "${ENV_FILE}" exec nginx-proxy nginx -t
docker compose --env-file "${ENV_FILE}" exec nginx-proxy nginx -s reload

echo "Certificates issued and HTTPS configs enabled."
