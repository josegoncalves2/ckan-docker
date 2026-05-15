sudo tee deploy_ckan.sh <<'EOFii'
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

ENV_FILE=".env"
ENV_EXAMPLE=".env.example"

usage() {
  cat <<EOF3
Usage: ./setup.sh [--skip-build] [--skip-up] [--help]

Options:
  --skip-build   Skip docker compose build
  --skip-up      Skip docker compose up -d
  --help         Show this help message

This script creates the local .env file, generates CKAN secrets, and starts the CKAN Docker stack.
EOF3
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





tee .env <<'EOF222'
# Host Ports
CKAN_PORT_HOST=5000
NGINX_PORT_HOST=81
NGINX_SSLPORT_HOST=8443

# CKAN databases
POSTGRES_USER=postgres
POSTGRES_PASSWORD=postgres
POSTGRES_DB=postgres
POSTGRES_HOST=db
CKAN_DB_USER=ckandbuser
CKAN_DB_PASSWORD=ckandbpassword
CKAN_DB=ckandb
DATASTORE_READONLY_USER=datastore_ro
DATASTORE_READONLY_PASSWORD=datastore
DATASTORE_DB=datastore
CKAN_SQLALCHEMY_URL=postgresql://ckandbuser:ckandbpassword@db/ckandb
CKAN_DATASTORE_WRITE_URL=postgresql://ckandbuser:ckandbpassword@db/datastore
CKAN_DATASTORE_READ_URL=postgresql://datastore_ro:datastore@db/datastore

# Test database connections
TEST_CKAN_SQLALCHEMY_URL=postgres://ckan:ckan@db/ckan_test
TEST_CKAN_DATASTORE_WRITE_URL=postgresql://ckan:ckan@db/datastore_test
TEST_CKAN_DATASTORE_READ_URL=postgresql://datastore_ro:datastore@db/datastore_test

# Dev settings
USE_HTTPS_FOR_DEV=false
CKAN__LOCALE__DEFAULT=pt_BR

# CKAN core
CKAN_VERSION=2.10.0
CKAN_SITE_ID=default
CKAN_SITE_URL=https://192.168.1.61:8443
CKAN___BEAKER__SESSION__SECRET=41a110a0ff6401c08ae145d44fa6d3b4f63ba24aed115d04de25ab677e5ba020
# See https://docs.ckan.org/en/latest/maintaining/configuration.html#api-token-settings
CKAN___API_TOKEN__JWT__ENCODE__SECRET=string:6e213480ebcc6fa6a4888097d1b606e757b568336e436615a47e7609ee0d62aa
CKAN___API_TOKEN__JWT__DECODE__SECRET=string:447b4247d92418c242fbe123236d685189ea675e148dea76145449dbb30956b3
CKAN_SYSADMIN_NAME=ckan_admin
CKAN_SYSADMIN_PASSWORD=admin1234
CKAN_SYSADMIN_EMAIL=admin@example.com
CKAN_STORAGE_PATH=/var/lib/ckan
CKAN_SMTP_SERVER=smtp.corporateict.domain:25
CKAN_SMTP_STARTTLS=True
CKAN_SMTP_USER=user
CKAN_SMTP_PASSWORD=pass
CKAN_SMTP_MAIL_FROM=ckan@localhost
CKAN_MAX_UPLOAD_SIZE_MB=100
TZ=UTC

# Solr
SOLR_IMAGE_VERSION=2.10-solr9
CKAN_SOLR_URL=http://solr:8983/solr/ckan
TEST_CKAN_SOLR_URL=http://solr:8983/solr/ckan

# Redis
REDIS_VERSION=6
CKAN_REDIS_URL=redis://redis:6379/1
TEST_CKAN_REDIS_URL=redis://redis:6379/1

# Datapusher
DATAPUSHER_VERSION=0.0.21
CKAN_DATAPUSHER_URL=http://datapusher:8800
CKAN__DATAPUSHER__CALLBACK_URL_BASE=http://ckan:5000

# NGINX
NGINX_PORT=80
NGINX_SSLPORT=443

# Extensions
CKAN__PLUGINS="image_view text_view datatables_view datastore datapusher envvars"
CKAN__HARVEST__MQ__TYPE=redis
CKAN__HARVEST__MQ__HOSTNAME=redis
CKAN__HARVEST__MQ__PORT=6379
CKAN__HARVEST__MQ__REDIS_DB=1
EOF222




cat <<EOF2

.env setup is complete.
Please review $ENV_FILE and adjust any values required for your environment, especially:
  - CKAN_SITE_URL
  - CKAN_SYSADMIN_NAME
  - CKAN_SYSADMIN_PASSWORD
  - CKAN_SYSADMIN_EMAIL
  - CKAN_STORAGE_PATH
  - CKAN__PLUGINS

EOF2

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

cat <<EOF4

Setup finished.
To see logs use: docker compose logs --tail 20
To stop the stack use: docker compose down
EOF4

EOFii

sudo chmod +x deploy_ckan.sh

sudo ./deploy_ckan.sh
