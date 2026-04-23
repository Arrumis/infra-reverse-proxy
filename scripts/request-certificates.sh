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
LETSENCRYPT_EMAIL="${LETSENCRYPT_EMAIL:-admin@${DOMAIN}}"
TLS_CERT_NAME="${TLS_CERT_NAME:-${ROOT_HOST}}"

domains=()
add_domain() {
  local domain_name="$1"
  local current

  [[ -z "${domain_name}" ]] && return 0

  for current in "${domains[@]}"; do
    if [[ "${current}" == "${domain_name}" ]]; then
      return 0
    fi
  done

  domains+=("${domain_name}")
}

add_domain "${ROOT_HOST}"
add_domain "${TTRSS_HOST}"
add_domain "${MUNIN_HOST}"
add_domain "${TATEGAKI_HOST}"
add_domain "${SYNCTHING_HOST}"
add_domain "${OPENVPN_HOST}"
add_domain "${TRAEFIK_HOST}"
add_domain "${MIRAKURUN_HOST}"
add_domain "${EPGREC_HOST}"
add_domain "${EPGSTATION_HOST}"

./scripts/render-configs.sh http
docker compose --env-file "${ENV_FILE}" up -d

certbot_args=()
for domain_name in "${domains[@]}"; do
  certbot_args+=(-d "${domain_name}")
done

docker compose --env-file "${ENV_FILE}" run --rm --entrypoint certbot certbot certonly \
  --webroot -w /usr/share/nginx/html \
  --agree-tos \
  --email "${LETSENCRYPT_EMAIL}" \
  --non-interactive \
  --cert-name "${TLS_CERT_NAME}" \
  --expand \
  "${certbot_args[@]}"

./scripts/render-configs.sh https
docker compose --env-file "${ENV_FILE}" exec nginx-proxy nginx -t
docker compose --env-file "${ENV_FILE}" exec nginx-proxy nginx -s reload

echo "Certificates issued and HTTPS configs enabled."
