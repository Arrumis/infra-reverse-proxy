#!/usr/bin/env bash
set -euo pipefail

mkdir -p data/traefik/dynamic data/letsencrypt data/log

if [[ ! -f data/letsencrypt/acme.json ]]; then
  touch data/letsencrypt/acme.json
fi

chmod 600 data/letsencrypt/acme.json

./scripts/render-configs.sh
echo "Initialized Traefik reverse proxy layout."
