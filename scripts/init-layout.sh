#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.local}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

umask 077

mkdir -p data/traefik/dynamic data/letsencrypt data/log

if [[ ! -f data/letsencrypt/acme.json ]]; then
  touch data/letsencrypt/acme.json
fi

chmod 600 data/letsencrypt/acme.json

BASIC_AUTH_USER="${BASIC_AUTH_USER:-admin}"
if [[ -z "${BASIC_AUTH_PASSWORD:-}" || "${BASIC_AUTH_PASSWORD}" == "change-me" ]]; then
  echo "BASIC_AUTH_PASSWORD に固有のパスワードを設定してください。" >&2
  exit 1
fi

if command -v openssl >/dev/null 2>&1; then
  printf '%s:%s\n' \
    "${BASIC_AUTH_USER}" \
    "$(printf '%s\n' "${BASIC_AUTH_PASSWORD}" | openssl passwd -apr1 -stdin)" > .htpasswd
  chmod 600 .htpasswd
else
  echo "openssl is required to generate .htpasswd" >&2
  exit 1
fi

./scripts/render-configs.sh
echo "Traefik リバースプロキシの配置を初期化しました。"
