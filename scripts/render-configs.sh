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
MUNIN_HOST="${MUNIN_HOST:-munin.${DOMAIN}}"
TATEGAKI_HOST="${TATEGAKI_HOST:-tategaki.${DOMAIN}}"
SYNCTHING_HOST="${SYNCTHING_HOST:-syncthing.${DOMAIN}}"
OPENVPN_HOST="${OPENVPN_HOST:-openvpn.${DOMAIN}}"
EPGREC_HOST="${EPGREC_HOST:-epgrec.${DOMAIN}}"
EPGSTATION_HOST="${EPGSTATION_HOST:-${EPGREC_HOST}}"
MIRAKURUN_HOST="${MIRAKURUN_HOST:-mirakurun.${DOMAIN}}"
WORDPRESS_UPSTREAM="${WORDPRESS_UPSTREAM:-127.0.0.1:8080}"
TTRSS_UPSTREAM="${TTRSS_UPSTREAM:-127.0.0.1:8280}"
MUNIN_UPSTREAM="${MUNIN_UPSTREAM:-127.0.0.1:8081}"
TATEGAKI_UPSTREAM="${TATEGAKI_UPSTREAM:-127.0.0.1:3000}"
SYNCTHING_UPSTREAM="${SYNCTHING_UPSTREAM:-127.0.0.1:8384}"
OPENVPN_ADMIN_UPSTREAM="${OPENVPN_ADMIN_UPSTREAM:-127.0.0.1:943}"
OPENVPN_CLIENT_UPSTREAM="${OPENVPN_CLIENT_UPSTREAM:-127.0.0.1:9443}"
MIRAKURUN_UPSTREAM="${MIRAKURUN_UPSTREAM:-127.0.0.1:40772}"
EPGSTATION_UPSTREAM="${EPGSTATION_UPSTREAM:-127.0.0.1:8888}"
TLS_CERT_NAME="${TLS_CERT_NAME:-${ROOT_HOST}}"

mkdir -p data/conf.d data/html/.well-known/acme-challenge data/letsencrypt data/log data/log_letsencrypt

rm -f \
  data/conf.d/default.conf \
  data/conf.d/ttrss-http.conf \
  data/conf.d/munin-http.conf \
  data/conf.d/tategaki-http.conf \
  data/conf.d/syncthing-http.conf \
  data/conf.d/openvpn-http.conf \
  data/conf.d/mirakurun-http.conf \
  data/conf.d/epgstation-http.conf \
  data/conf.d/wordpress-https.conf \
  data/conf.d/ttrss-https.conf \
  data/conf.d/munin-https.conf \
  data/conf.d/tategaki-https.conf \
  data/conf.d/syncthing-https.conf \
  data/conf.d/openvpn-https.conf \
  data/conf.d/mirakurun-https.conf \
  data/conf.d/epgstation-https.conf
cp templates/logformat.conf data/conf.d/logformat.conf

case "${MODE}" in
  http)
    envsubst '${ROOT_HOST} ${WORDPRESS_UPSTREAM}' < templates/wordpress_http.conf > data/conf.d/default.conf
    envsubst '${TTRSS_HOST} ${TTRSS_UPSTREAM}' < templates/ttrss_http.conf > data/conf.d/ttrss-http.conf
    envsubst '${MUNIN_HOST} ${MUNIN_UPSTREAM}' < templates/munin_http.conf > data/conf.d/munin-http.conf
    envsubst '${TATEGAKI_HOST} ${TATEGAKI_UPSTREAM}' < templates/tategaki_http.conf > data/conf.d/tategaki-http.conf
    envsubst '${SYNCTHING_HOST} ${SYNCTHING_UPSTREAM}' < templates/syncthing_http.conf > data/conf.d/syncthing-http.conf
    envsubst '${OPENVPN_HOST} ${OPENVPN_ADMIN_UPSTREAM} ${OPENVPN_CLIENT_UPSTREAM}' < templates/openvpn_http.conf > data/conf.d/openvpn-http.conf
    envsubst '${MIRAKURUN_HOST} ${MIRAKURUN_UPSTREAM}' < templates/mirakurun_http.conf > data/conf.d/mirakurun-http.conf
    envsubst '${EPGREC_HOST} ${EPGSTATION_UPSTREAM}' < templates/epgstation_http.conf > data/conf.d/epgstation-http.conf
    ;;
  https)
    envsubst '${ROOT_HOST}' < templates/wordpress_http_redirect.conf > data/conf.d/default.conf
    envsubst '${TTRSS_HOST}' < templates/ttrss_http_redirect.conf > data/conf.d/ttrss-http.conf
    envsubst '${MUNIN_HOST}' < templates/munin_http_redirect.conf > data/conf.d/munin-http.conf
    envsubst '${TATEGAKI_HOST}' < templates/tategaki_http_redirect.conf > data/conf.d/tategaki-http.conf
    envsubst '${SYNCTHING_HOST}' < templates/syncthing_http_redirect.conf > data/conf.d/syncthing-http.conf
    envsubst '${OPENVPN_HOST}' < templates/openvpn_http_redirect.conf > data/conf.d/openvpn-http.conf
    envsubst '${MIRAKURUN_HOST}' < templates/mirakurun_http_redirect.conf > data/conf.d/mirakurun-http.conf
    envsubst '${EPGREC_HOST}' < templates/epgstation_http_redirect.conf > data/conf.d/epgstation-http.conf
    DOMAIN="${DOMAIN}" ROOT_HOST="${ROOT_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" WORDPRESS_UPSTREAM="${WORDPRESS_UPSTREAM}" \
      envsubst '${DOMAIN} ${ROOT_HOST} ${TLS_CERT_NAME} ${WORDPRESS_UPSTREAM}' < templates/wordpress_proxy.conf > data/conf.d/wordpress-https.conf
    DOMAIN="${DOMAIN}" TTRSS_HOST="${TTRSS_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" TTRSS_UPSTREAM="${TTRSS_UPSTREAM}" \
      envsubst '${DOMAIN} ${TTRSS_HOST} ${TLS_CERT_NAME} ${TTRSS_UPSTREAM}' < templates/ttrss_proxy.conf > data/conf.d/ttrss-https.conf
    DOMAIN="${DOMAIN}" MUNIN_HOST="${MUNIN_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" MUNIN_UPSTREAM="${MUNIN_UPSTREAM}" \
      envsubst '${DOMAIN} ${MUNIN_HOST} ${TLS_CERT_NAME} ${MUNIN_UPSTREAM}' < templates/munin_proxy.conf > data/conf.d/munin-https.conf
    DOMAIN="${DOMAIN}" TATEGAKI_HOST="${TATEGAKI_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" TATEGAKI_UPSTREAM="${TATEGAKI_UPSTREAM}" \
      envsubst '${DOMAIN} ${TATEGAKI_HOST} ${TLS_CERT_NAME} ${TATEGAKI_UPSTREAM}' < templates/tategaki_proxy.conf > data/conf.d/tategaki-https.conf
    DOMAIN="${DOMAIN}" SYNCTHING_HOST="${SYNCTHING_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" SYNCTHING_UPSTREAM="${SYNCTHING_UPSTREAM}" \
      envsubst '${DOMAIN} ${SYNCTHING_HOST} ${TLS_CERT_NAME} ${SYNCTHING_UPSTREAM}' < templates/syncthing_proxy.conf > data/conf.d/syncthing-https.conf
    DOMAIN="${DOMAIN}" OPENVPN_HOST="${OPENVPN_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" OPENVPN_ADMIN_UPSTREAM="${OPENVPN_ADMIN_UPSTREAM}" OPENVPN_CLIENT_UPSTREAM="${OPENVPN_CLIENT_UPSTREAM}" \
      envsubst '${DOMAIN} ${OPENVPN_HOST} ${TLS_CERT_NAME} ${OPENVPN_ADMIN_UPSTREAM} ${OPENVPN_CLIENT_UPSTREAM}' < templates/openvpn_proxy.conf > data/conf.d/openvpn-https.conf
    DOMAIN="${DOMAIN}" MIRAKURUN_HOST="${MIRAKURUN_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" MIRAKURUN_UPSTREAM="${MIRAKURUN_UPSTREAM}" \
      envsubst '${DOMAIN} ${MIRAKURUN_HOST} ${TLS_CERT_NAME} ${MIRAKURUN_UPSTREAM}' < templates/mirakurun_proxy.conf > data/conf.d/mirakurun-https.conf
    DOMAIN="${DOMAIN}" EPGREC_HOST="${EPGREC_HOST}" TLS_CERT_NAME="${TLS_CERT_NAME}" EPGSTATION_UPSTREAM="${EPGSTATION_UPSTREAM}" \
      envsubst '${DOMAIN} ${EPGREC_HOST} ${TLS_CERT_NAME} ${EPGSTATION_UPSTREAM}' < templates/epgstation_proxy.conf > data/conf.d/epgstation-https.conf
    ;;
  *)
    echo "Usage: $0 [http|https]"
    exit 1
    ;;
esac

echo "Rendered proxy configs for mode: ${MODE}"
