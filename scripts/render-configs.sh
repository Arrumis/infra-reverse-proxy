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
TRAEFIK_HOST="${TRAEFIK_HOST:-traefik.${DOMAIN}}"
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
mkdir -p data/html/proxy-dashboard

has_cert() {
  local cert_name="$1"

  [[ -z "${cert_name}" ]] && return 1

  if [[ -f "data/letsencrypt/renewal/${cert_name}.conf" ]]; then
    return 0
  fi

  if [[ -f "data/letsencrypt/live/${cert_name}/fullchain.pem" && -f "data/letsencrypt/live/${cert_name}/privkey.pem" ]]; then
    return 0
  fi

  return 1
}

rm -f \
  data/conf.d/default.conf \
  data/conf.d/ttrss-http.conf \
  data/conf.d/munin-http.conf \
  data/conf.d/tategaki-http.conf \
  data/conf.d/syncthing-http.conf \
  data/conf.d/openvpn-http.conf \
  data/conf.d/traefik-http.conf \
  data/conf.d/mirakurun-http.conf \
  data/conf.d/epgrec-http.conf \
  data/conf.d/epgstation-http.conf \
  data/conf.d/wordpress-https.conf \
  data/conf.d/ttrss-https.conf \
  data/conf.d/munin-https.conf \
  data/conf.d/tategaki-https.conf \
  data/conf.d/syncthing-https.conf \
  data/conf.d/openvpn-https.conf \
  data/conf.d/traefik-https.conf \
  data/conf.d/mirakurun-https.conf \
  data/conf.d/epgrec-https.conf \
  data/conf.d/epgstation-https.conf
cp templates/logformat.conf data/conf.d/logformat.conf
envsubst '${ROOT_HOST} ${TTRSS_HOST} ${MUNIN_HOST} ${TATEGAKI_HOST} ${SYNCTHING_HOST} ${OPENVPN_HOST} ${TRAEFIK_HOST} ${EPGREC_HOST} ${MIRAKURUN_HOST} ${TLS_CERT_NAME}' \
  < templates/proxy_dashboard.html > data/html/proxy-dashboard/index.html

case "${MODE}" in
  http)
    envsubst '${ROOT_HOST} ${WORDPRESS_UPSTREAM}' < templates/wordpress_http.conf > data/conf.d/default.conf
    envsubst '${TTRSS_HOST} ${TTRSS_UPSTREAM}' < templates/ttrss_http.conf > data/conf.d/ttrss-http.conf
    envsubst '${MUNIN_HOST} ${MUNIN_UPSTREAM}' < templates/munin_http.conf > data/conf.d/munin-http.conf
    envsubst '${TATEGAKI_HOST} ${TATEGAKI_UPSTREAM}' < templates/tategaki_http.conf > data/conf.d/tategaki-http.conf
    envsubst '${SYNCTHING_HOST} ${SYNCTHING_UPSTREAM}' < templates/syncthing_http.conf > data/conf.d/syncthing-http.conf
    envsubst '${OPENVPN_HOST} ${OPENVPN_ADMIN_UPSTREAM} ${OPENVPN_CLIENT_UPSTREAM}' < templates/openvpn_http.conf > data/conf.d/openvpn-http.conf
    envsubst '${TRAEFIK_HOST}' < templates/traefik_http.conf > data/conf.d/traefik-http.conf
    envsubst '${MIRAKURUN_HOST} ${MIRAKURUN_UPSTREAM}' < templates/mirakurun_http.conf > data/conf.d/mirakurun-http.conf
    SERVER_HOST="${EPGREC_HOST}" EPGSTATION_UPSTREAM="${EPGSTATION_UPSTREAM}" \
      envsubst '${SERVER_HOST} ${EPGSTATION_UPSTREAM}' < templates/epgstation_http.conf > data/conf.d/epgrec-http.conf
    if [[ "${EPGSTATION_HOST}" != "${EPGREC_HOST}" ]]; then
      SERVER_HOST="${EPGSTATION_HOST}" EPGSTATION_UPSTREAM="${EPGSTATION_UPSTREAM}" \
        envsubst '${SERVER_HOST} ${EPGSTATION_UPSTREAM}' < templates/epgstation_http.conf > data/conf.d/epgstation-http.conf
    fi
    ;;
  https)
    if has_cert "${ROOT_HOST}"; then
      envsubst '${ROOT_HOST}' < templates/wordpress_http_redirect.conf > data/conf.d/default.conf
      DOMAIN="${DOMAIN}" ROOT_HOST="${ROOT_HOST}" CERT_NAME="${ROOT_HOST}" WORDPRESS_UPSTREAM="${WORDPRESS_UPSTREAM}" \
        envsubst '${DOMAIN} ${ROOT_HOST} ${CERT_NAME} ${WORDPRESS_UPSTREAM}' < templates/wordpress_proxy.conf > data/conf.d/wordpress-https.conf
    else
      envsubst '${ROOT_HOST} ${WORDPRESS_UPSTREAM}' < templates/wordpress_http.conf > data/conf.d/default.conf
    fi

    if has_cert "${TTRSS_HOST}"; then
      envsubst '${TTRSS_HOST}' < templates/ttrss_http_redirect.conf > data/conf.d/ttrss-http.conf
      DOMAIN="${DOMAIN}" TTRSS_HOST="${TTRSS_HOST}" CERT_NAME="${TTRSS_HOST}" TTRSS_UPSTREAM="${TTRSS_UPSTREAM}" \
        envsubst '${DOMAIN} ${TTRSS_HOST} ${CERT_NAME} ${TTRSS_UPSTREAM}' < templates/ttrss_proxy.conf > data/conf.d/ttrss-https.conf
    else
      envsubst '${TTRSS_HOST} ${TTRSS_UPSTREAM}' < templates/ttrss_http.conf > data/conf.d/ttrss-http.conf
    fi

    if has_cert "${MUNIN_HOST}"; then
      envsubst '${MUNIN_HOST}' < templates/munin_http_redirect.conf > data/conf.d/munin-http.conf
      DOMAIN="${DOMAIN}" MUNIN_HOST="${MUNIN_HOST}" CERT_NAME="${MUNIN_HOST}" MUNIN_UPSTREAM="${MUNIN_UPSTREAM}" \
        envsubst '${DOMAIN} ${MUNIN_HOST} ${CERT_NAME} ${MUNIN_UPSTREAM}' < templates/munin_proxy.conf > data/conf.d/munin-https.conf
    else
      envsubst '${MUNIN_HOST} ${MUNIN_UPSTREAM}' < templates/munin_http.conf > data/conf.d/munin-http.conf
    fi

    if has_cert "${TATEGAKI_HOST}"; then
      envsubst '${TATEGAKI_HOST}' < templates/tategaki_http_redirect.conf > data/conf.d/tategaki-http.conf
      DOMAIN="${DOMAIN}" TATEGAKI_HOST="${TATEGAKI_HOST}" CERT_NAME="${TATEGAKI_HOST}" TATEGAKI_UPSTREAM="${TATEGAKI_UPSTREAM}" \
        envsubst '${DOMAIN} ${TATEGAKI_HOST} ${CERT_NAME} ${TATEGAKI_UPSTREAM}' < templates/tategaki_proxy.conf > data/conf.d/tategaki-https.conf
    else
      envsubst '${TATEGAKI_HOST} ${TATEGAKI_UPSTREAM}' < templates/tategaki_http.conf > data/conf.d/tategaki-http.conf
    fi

    if has_cert "${SYNCTHING_HOST}"; then
      envsubst '${SYNCTHING_HOST}' < templates/syncthing_http_redirect.conf > data/conf.d/syncthing-http.conf
      DOMAIN="${DOMAIN}" SYNCTHING_HOST="${SYNCTHING_HOST}" CERT_NAME="${SYNCTHING_HOST}" SYNCTHING_UPSTREAM="${SYNCTHING_UPSTREAM}" \
        envsubst '${DOMAIN} ${SYNCTHING_HOST} ${CERT_NAME} ${SYNCTHING_UPSTREAM}' < templates/syncthing_proxy.conf > data/conf.d/syncthing-https.conf
    else
      envsubst '${SYNCTHING_HOST} ${SYNCTHING_UPSTREAM}' < templates/syncthing_http.conf > data/conf.d/syncthing-http.conf
    fi

    if has_cert "${OPENVPN_HOST}"; then
      envsubst '${OPENVPN_HOST}' < templates/openvpn_http_redirect.conf > data/conf.d/openvpn-http.conf
      DOMAIN="${DOMAIN}" OPENVPN_HOST="${OPENVPN_HOST}" CERT_NAME="${OPENVPN_HOST}" OPENVPN_ADMIN_UPSTREAM="${OPENVPN_ADMIN_UPSTREAM}" OPENVPN_CLIENT_UPSTREAM="${OPENVPN_CLIENT_UPSTREAM}" \
        envsubst '${DOMAIN} ${OPENVPN_HOST} ${CERT_NAME} ${OPENVPN_ADMIN_UPSTREAM} ${OPENVPN_CLIENT_UPSTREAM}' < templates/openvpn_proxy.conf > data/conf.d/openvpn-https.conf
    else
      envsubst '${OPENVPN_HOST} ${OPENVPN_ADMIN_UPSTREAM} ${OPENVPN_CLIENT_UPSTREAM}' < templates/openvpn_http.conf > data/conf.d/openvpn-http.conf
    fi

    if has_cert "${TRAEFIK_HOST}"; then
      envsubst '${TRAEFIK_HOST}' < templates/traefik_http_redirect.conf > data/conf.d/traefik-http.conf
      DOMAIN="${DOMAIN}" TRAEFIK_HOST="${TRAEFIK_HOST}" CERT_NAME="${TRAEFIK_HOST}" \
        envsubst '${DOMAIN} ${TRAEFIK_HOST} ${CERT_NAME}' < templates/traefik_proxy.conf > data/conf.d/traefik-https.conf
    else
      envsubst '${TRAEFIK_HOST}' < templates/traefik_http.conf > data/conf.d/traefik-http.conf
    fi

    if has_cert "${MIRAKURUN_HOST}"; then
      envsubst '${MIRAKURUN_HOST}' < templates/mirakurun_http_redirect.conf > data/conf.d/mirakurun-http.conf
      DOMAIN="${DOMAIN}" MIRAKURUN_HOST="${MIRAKURUN_HOST}" CERT_NAME="${MIRAKURUN_HOST}" MIRAKURUN_UPSTREAM="${MIRAKURUN_UPSTREAM}" \
        envsubst '${DOMAIN} ${MIRAKURUN_HOST} ${CERT_NAME} ${MIRAKURUN_UPSTREAM}' < templates/mirakurun_proxy.conf > data/conf.d/mirakurun-https.conf
    else
      envsubst '${MIRAKURUN_HOST} ${MIRAKURUN_UPSTREAM}' < templates/mirakurun_http.conf > data/conf.d/mirakurun-http.conf
    fi

    if has_cert "${EPGREC_HOST}"; then
      SERVER_HOST="${EPGREC_HOST}" envsubst '${SERVER_HOST}' < templates/epgstation_http_redirect.conf > data/conf.d/epgrec-http.conf
      DOMAIN="${DOMAIN}" SERVER_HOST="${EPGREC_HOST}" CERT_NAME="${EPGREC_HOST}" EPGSTATION_UPSTREAM="${EPGSTATION_UPSTREAM}" \
        envsubst '${DOMAIN} ${SERVER_HOST} ${CERT_NAME} ${EPGSTATION_UPSTREAM}' < templates/epgstation_proxy.conf > data/conf.d/epgrec-https.conf
    else
      SERVER_HOST="${EPGREC_HOST}" EPGSTATION_UPSTREAM="${EPGSTATION_UPSTREAM}" \
        envsubst '${SERVER_HOST} ${EPGSTATION_UPSTREAM}' < templates/epgstation_http.conf > data/conf.d/epgrec-http.conf
    fi

    if [[ "${EPGSTATION_HOST}" != "${EPGREC_HOST}" ]]; then
      if has_cert "${EPGSTATION_HOST}"; then
        SERVER_HOST="${EPGSTATION_HOST}" envsubst '${SERVER_HOST}' < templates/epgstation_http_redirect.conf > data/conf.d/epgstation-http.conf
        DOMAIN="${DOMAIN}" SERVER_HOST="${EPGSTATION_HOST}" CERT_NAME="${EPGSTATION_HOST}" EPGSTATION_UPSTREAM="${EPGSTATION_UPSTREAM}" \
          envsubst '${DOMAIN} ${SERVER_HOST} ${CERT_NAME} ${EPGSTATION_UPSTREAM}' < templates/epgstation_proxy.conf > data/conf.d/epgstation-https.conf
      else
        SERVER_HOST="${EPGSTATION_HOST}" EPGSTATION_UPSTREAM="${EPGSTATION_UPSTREAM}" \
          envsubst '${SERVER_HOST} ${EPGSTATION_UPSTREAM}' < templates/epgstation_http.conf > data/conf.d/epgstation-http.conf
      fi
    fi
    ;;
  *)
    echo "Usage: $0 [http|https]"
    exit 1
    ;;
esac

echo "Rendered proxy configs for mode: ${MODE}"
