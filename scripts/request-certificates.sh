#!/usr/bin/env bash
set -euo pipefail

ENV_FILE="${ENV_FILE:-.env.local}"
if [[ -f "${ENV_FILE}" ]]; then
  set -a
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  set +a
fi

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required" >&2
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
MIRAKURUN_HOST="${MIRAKURUN_HOST:-mirakurun.${DOMAIN}}"
EPGREC_HOST="${EPGREC_HOST:-epgrec.${DOMAIN}}"
EPGSTATION_HOST="${EPGSTATION_HOST:-${EPGREC_HOST}}"

declare -a checks=(
  "${ROOT_HOST}|/"
  "${TTRSS_HOST}|/tt-rss/"
  "${MUNIN_HOST}|/"
  "${TATEGAKI_HOST}|/"
  "${SYNCTHING_HOST}|/"
  "${OPENVPN_HOST}|/admin"
  "${TRAEFIK_HOST}|/dashboard/"
  "${MIRAKURUN_HOST}|/"
  "${EPGREC_HOST}|/"
)

if [[ "${EPGSTATION_HOST}" != "${EPGREC_HOST}" ]]; then
  checks+=("${EPGSTATION_HOST}|/")
fi

./scripts/render-configs.sh
docker compose --env-file "${ENV_FILE}" up -d

sleep 3

failures=()

trigger_host() {
  local host="$1"
  local path="$2"
  local attempt

  for attempt in 1 2 3 4 5; do
    if curl -kfsSI --resolve "${host}:443:127.0.0.1" "https://${host}${path}" >/dev/null 2>&1; then
      return 0
    fi
    sleep 5
  done

  return 1
}

for item in "${checks[@]}"; do
  host="${item%%|*}"
  path="${item#*|}"
  if ! trigger_host "${host}" "${path}"; then
    failures+=("${host}")
  fi
done

if [[ "${#failures[@]}" -gt 0 ]]; then
  printf 'Certificate acquisition failed for:%s\n' " ${failures[*]}" >&2
  exit 1
fi

echo "Traefik ACME requests completed."
