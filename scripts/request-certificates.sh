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
PREVIOUS_MODE="http"

if compgen -G "data/letsencrypt/renewal/*.conf" >/dev/null || compgen -G "data/letsencrypt/live/*/fullchain.pem" >/dev/null; then
  PREVIOUS_MODE="https"
fi

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

restore_previous_mode() {
  ./scripts/render-configs.sh "${PREVIOUS_MODE}"
  docker compose --env-file "${ENV_FILE}" up -d
  if docker compose --env-file "${ENV_FILE}" exec -T nginx-proxy nginx -t >/dev/null 2>&1; then
    docker compose --env-file "${ENV_FILE}" exec -T nginx-proxy nginx -s reload >/dev/null 2>&1 || true
  fi
}

./scripts/render-configs.sh http
docker compose --env-file "${ENV_FILE}" up -d

success_count=0
failed_domains=()

for domain_name in "${domains[@]}"; do
  if docker compose --env-file "${ENV_FILE}" run --rm --entrypoint certbot certbot certonly \
    --webroot -w /usr/share/nginx/html \
    --agree-tos \
    --email "${LETSENCRYPT_EMAIL}" \
    --non-interactive \
    --cert-name "${domain_name}" \
    -d "${domain_name}"; then
    success_count=$((success_count + 1))
    continue
  fi

  failed_domains+=("${domain_name}")
done

if [[ "${success_count}" -eq 0 ]] && [[ "${PREVIOUS_MODE}" == "http" ]]; then
  restore_previous_mode
  echo "Certificate request failed for all hosts; restored previous proxy mode: ${PREVIOUS_MODE}" >&2
  exit 1
fi

./scripts/render-configs.sh https
docker compose --env-file "${ENV_FILE}" exec nginx-proxy nginx -t
docker compose --env-file "${ENV_FILE}" exec nginx-proxy nginx -s reload

if [[ "${#failed_domains[@]}" -gt 0 ]]; then
  printf 'Certificates failed for:%s\n' " ${failed_domains[*]}" >&2
fi

echo "Certificates processed and HTTPS configs enabled."
