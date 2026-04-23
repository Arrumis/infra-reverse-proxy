#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.local}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

MODE="${1:-http}"

if ! command -v envsubst >/dev/null 2>&1; then
  echo "envsubst is required"
  exit 1
fi

DOMAIN="${DOMAIN:-example.local}"
ROOT_HOST="${ROOT_HOST:-${DOMAIN}}"
TTRSS_HOST="${TTRSS_HOST:-ttrss.${DOMAIN}}"
WORDPRESS_UPSTREAM="${WORDPRESS_UPSTREAM:-127.0.0.1:8080}"
TTRSS_UPSTREAM="${TTRSS_UPSTREAM:-127.0.0.1:8280}"
TLS_CERT_NAME="${TLS_CERT_NAME:-${ROOT_HOST}}"

mkdir -p data/conf.d data/html/.well-known/acme-challenge data/letsencrypt data/log data/log_letsencrypt

rm -f data/conf.d/default.conf data/conf.d/ttrss-http.conf data/conf.d/wordpress-https.conf data/conf.d/ttrss-https.conf
cp templates/logformat.conf data/conf.d/logformat.conf

case "${MODE}" in
  http)
    envsubst '${ROOT_HOST} ${WORDPRESS_UPSTREAM}' < templates/wordpress_http.conf > data/conf.d/default.conf
    envsubst '${TTRSS_HOST} ${TTRSS_UPSTREAM}' < templates/ttrss_http.conf > data/conf.d/ttrss-http.conf
    ;;
  https)
    envsubst '${ROOT_HOST}' < templates/wordpress_http_redirect.conf > data/conf.d/default.conf
    envsubst '${TTRSS_HOST}' < templates/ttrss_http_redirect.conf > data/conf.d/ttrss-http.conf
    DOMAIN="${DOMAIN}" ROOT_HOST="${ROOT_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" WORDPRESS_UPSTREAM="${WORDPRESS_UPSTREAM}" \
      envsubst '${DOMAIN} ${ROOT_HOST} ${TLS_CERT_NAME} ${WORDPRESS_UPSTREAM}' < templates/wordpress_proxy.conf > data/conf.d/wordpress-https.conf
    DOMAIN="${DOMAIN}" TTRSS_HOST="${TTRSS_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" TTRSS_UPSTREAM="${TTRSS_UPSTREAM}" \
      envsubst '${DOMAIN} ${TTRSS_HOST} ${TLS_CERT_NAME} ${TTRSS_UPSTREAM}' < templates/ttrss_proxy.conf > data/conf.d/ttrss-https.conf
    ;;
  *)
    echo "Usage: $0 [http|https]"
    exit 1
    ;;
esac

echo "Rendered proxy configs for mode: ${MODE}"
