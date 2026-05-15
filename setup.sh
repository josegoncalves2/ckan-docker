#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

usage() {
  cat <<EOF
Usage: ./setup.sh [--skip-build] [--skip-up] [--help]

Options:
  --skip-build   Skip docker compose build
  --skip-up      Skip docker compose up -d
  --help         Show this help message

This script creates the local .env file, generates CKAN secrets, and starts the CKAN Docker stack.
EOF
}

SKIP_BUILD=false
SKIP_UP=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --skip-up)
      SKIP_UP=true
      shift
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ ! -f "$ENV_EXAMPLE" ]]; then
  echo "ERROR: $ENV_EXAMPLE not found. Run this script from the repository root."
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker is not installed or not on PATH."
  exit 1
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "ERROR: docker compose is not available. Use Docker Compose v2 with 'docker compose'."
  exit 1
fi

if [[ ! -f "$ENV_FILE" ]]; then
  cp "$ENV_EXAMPLE" "$ENV_FILE"
  echo "Created local $ENV_FILE from $ENV_EXAMPLE"
else
  echo "$ENV_FILE already exists. Keeping existing file."
fi

# Generate a secure random value using openssl or python3
generate_secret() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 32
  elif command -v python3 >/dev/null 2>&1; then
    python3 -c 'import secrets; print(secrets.token_hex(32))'
  else
    echo "ERROR: neither openssl nor python3 is available to generate secrets."
    exit 1
  fi
}

replace_if_placeholder() {
  local key="$1"
  local placeholder="$2"
  local value="$3"
  if grep -qE "^${key}=${placeholder}" "$ENV_FILE"; then
    sed -i.bak -E "s/^(${key})=.*/\1=${value}/" "$ENV_FILE"
    rm -f "${ENV_FILE}.bak"
    echo "Set ${key} in $ENV_FILE"
  fi
}

replace_if_placeholder "CKAN___BEAKER__SESSION__SECRET" "CHANGE_ME" "$(generate_secret)"
replace_if_placeholder "CKAN___API_TOKEN__JWT__ENCODE__SECRET" "string:CHANGE_ME" "string:$(generate_secret)"
replace_if_placeholder "CKAN___API_TOKEN__JWT__DECODE__SECRET" "string:CHANGE_ME" "string:$(generate_secret)"
replace_if_placeholder "CKAN_SYSADMIN_EMAIL" "your_email@example.com" "admin@example.com"
replace_if_placeholder "CKAN_SYSADMIN_PASSWORD" "test1234" "admin1234"

cat <<EOF

.env setup is complete.
Please review $ENV_FILE and adjust any values required for your environment, especially:
  - CKAN_SITE_URL
  - CKAN_SYSADMIN_NAME
  - CKAN_SYSADMIN_PASSWORD
  - CKAN_SYSADMIN_EMAIL
  - CKAN_STORAGE_PATH
  - CKAN__PLUGINS

EOF

if [[ "$SKIP_BUILD" == false ]]; then
  echo "Building Docker images..."
  docker compose build
else
  echo "Skipping docker compose build."
fi

if [[ "$SKIP_UP" == false ]]; then
  echo "Starting Docker Compose stack..."
  docker compose up -d
  echo "Waiting for containers to initialize..."
  sleep 5
  docker compose ps
else
  echo "Skipping docker compose up -d."
fi

cat <<EOF

Setup finished.
To see logs use: docker compose logs --tail 20
To stop the stack use: docker compose down
EOF
