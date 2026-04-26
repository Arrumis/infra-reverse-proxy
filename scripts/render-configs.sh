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
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-admin@${DOMAIN}}"
HTTP_PORT="${HTTP_PORT:-80}"
HTTPS_PORT="${HTTPS_PORT:-443}"
TRAEFIK_INTERNAL_PORT="${TRAEFIK_INTERNAL_PORT:-8088}"
TRAEFIK_LOG_LEVEL="${TRAEFIK_LOG_LEVEL:-INFO}"

mkdir -p data/traefik/dynamic data/letsencrypt data/log

static_config="data/traefik/traefik.yml"
dynamic_config="data/traefik/dynamic/routes.yml"
routers_tmp="$(mktemp)"
services_tmp="$(mktemp)"
trap 'rm -f "${routers_tmp}" "${services_tmp}"' EXIT

emit_redirect_router() {
  local name="$1"
  local rule="$2"
  local service="$3"
  local priority="${4:-100}"

  cat >>"${routers_tmp}" <<EOF
    ${name}-http:
      entryPoints:
        - web
      rule: "${rule}"
      middlewares:
        - https-redirect
      priority: ${priority}
      service: ${service}
EOF
}

emit_tls_router() {
  local name="$1"
  local rule="$2"
  local service="$3"
  local priority="${4:-100}"
  local middlewares="${5:-}"

  cat >>"${routers_tmp}" <<EOF
    ${name}-https:
      entryPoints:
        - websecure
      rule: "${rule}"
      priority: ${priority}
EOF
  if [[ -n "${middlewares}" ]]; then
    cat >>"${routers_tmp}" <<EOF
      middlewares:
${middlewares}
EOF
  fi
  cat >>"${routers_tmp}" <<EOF
      service: ${service}
      tls:
        certResolver: letsencrypt
EOF
}

emit_service_url() {
  local name="$1"
  local url="$2"
  local transport="${3:-}"

  cat >>"${services_tmp}" <<EOF
    ${name}:
      loadBalancer:
EOF
  if [[ -n "${transport}" ]]; then
    cat >>"${services_tmp}" <<EOF
        serversTransport: ${transport}
EOF
  fi
  cat >>"${services_tmp}" <<EOF
        servers:
          - url: "${url}"
EOF
}

emit_standard_host() {
  local name="$1"
  local host="$2"
  local url="$3"
  local transport="${4:-}"
  local middlewares="${5:-}"

  emit_redirect_router "${name}" "Host(\`${host}\`)" "${name}" 100
  emit_tls_router "${name}" "Host(\`${host}\`)" "${name}" 100 "${middlewares}"
  emit_service_url "${name}" "${url}" "${transport}"
}

emit_standard_host "wordpress" "${ROOT_HOST}" "http://${WORDPRESS_UPSTREAM}"
emit_standard_host "ttrss" "${TTRSS_HOST}" "http://${TTRSS_UPSTREAM}"
emit_standard_host "tategaki" "${TATEGAKI_HOST}" "http://${TATEGAKI_UPSTREAM}"
emit_standard_host "syncthing" "${SYNCTHING_HOST}" "http://${SYNCTHING_UPSTREAM}"
emit_standard_host "mirakurun" "${MIRAKURUN_HOST}" "http://${MIRAKURUN_UPSTREAM}" "" $'        - protected-basic-auth'
emit_standard_host "epgrec" "${EPGREC_HOST}" "http://${EPGSTATION_UPSTREAM}" "" $'        - protected-basic-auth'

if [[ "${EPGSTATION_HOST}" != "${EPGREC_HOST}" ]]; then
  emit_standard_host "epgstation" "${EPGSTATION_HOST}" "http://${EPGSTATION_UPSTREAM}" "" $'        - protected-basic-auth'
fi

emit_redirect_router "openvpn-admin" "Host(\`${OPENVPN_HOST}\`) && PathPrefix(\`/admin\`)" "openvpn-admin" 200
emit_tls_router "openvpn-admin" "Host(\`${OPENVPN_HOST}\`) && PathPrefix(\`/admin\`)" "openvpn-admin" 200
emit_service_url "openvpn-admin" "https://${OPENVPN_ADMIN_UPSTREAM}" "insecure-skip-verify"

emit_redirect_router "openvpn-client" "Host(\`${OPENVPN_HOST}\`)" "openvpn-admin" 100
emit_tls_router "openvpn-client" "Host(\`${OPENVPN_HOST}\`)" "openvpn-admin" 100

emit_redirect_router "traefik" "Host(\`${TRAEFIK_HOST}\`)" "api@internal" 100
emit_redirect_router "munin" "Host(\`${MUNIN_HOST}\`)" "munin" 100
cat >>"${routers_tmp}" <<EOF
    munin-https:
      entryPoints:
        - websecure
      rule: "Host(\`${MUNIN_HOST}\`)"
      priority: 100
      middlewares:
        - protected-basic-auth
        - munin-prefix
      service: munin
      tls:
        certResolver: letsencrypt
EOF
emit_service_url "munin" "http://${MUNIN_UPSTREAM}"
cat >>"${routers_tmp}" <<EOF
    traefik-root-https:
      entryPoints:
        - websecure
      rule: "Host(\`${TRAEFIK_HOST}\`) && Path(\`/\`)"
      middlewares:
        - protected-basic-auth
        - traefik-dashboard-root
      priority: 200
      service: api@internal
      tls:
        certResolver: letsencrypt
    traefik-dashboard-https:
      entryPoints:
        - websecure
      rule: "Host(\`${TRAEFIK_HOST}\`) && (PathPrefix(\`/api\`) || PathPrefix(\`/dashboard\`))"
      priority: 100
      middlewares:
        - protected-basic-auth
      service: api@internal
      tls:
        certResolver: letsencrypt
EOF

cat >"${static_config}" <<EOF
api:
  dashboard: true

log:
  level: ${TRAEFIK_LOG_LEVEL}

accessLog:
  filePath: /var/log/traefik/access.log

entryPoints:
  web:
    address: :${HTTP_PORT}
  websecure:
    address: :${HTTPS_PORT}
  traefik:
    address: 127.0.0.1:${TRAEFIK_INTERNAL_PORT}

providers:
  file:
    filename: /etc/traefik/dynamic/routes.yml
    watch: true

certificatesResolvers:
  letsencrypt:
    acme:
      email: ${LETSENCRYPT_EMAIL}
      storage: /letsencrypt/acme.json
      httpChallenge:
        entryPoint: web

ping: {}
EOF

cat >"${dynamic_config}" <<EOF
http:
  middlewares:
    https-redirect:
      redirectScheme:
        scheme: https
        permanent: true
    protected-basic-auth:
      basicAuth:
        usersFile: /etc/traefik/.htpasswd
    traefik-dashboard-root:
      redirectRegex:
        regex: "^https?://([^/]+)/?$"
        replacement: "https://\${1}/dashboard/"
        permanent: true
    munin-prefix:
      addPrefix:
        prefix: /munin

  serversTransports:
    insecure-skip-verify:
      insecureSkipVerify: true

  routers:
EOF
cat "${routers_tmp}" >>"${dynamic_config}"
cat >>"${dynamic_config}" <<EOF

  services:
EOF
cat "${services_tmp}" >>"${dynamic_config}"

echo "Rendered Traefik configuration."
