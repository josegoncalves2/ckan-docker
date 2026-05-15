tee deploy_ckan.sh <<'EOFii'
#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/opt/projetos/ckan"
ENV_FILE="${APP_DIR}/.env"
COMPOSE_FILE="${APP_DIR}/docker-compose.yml"

# Cores para output
GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
msg()  { echo -e "${BLUE}==>${NC} $1"; }
ok()   { echo -e "${GREEN}✔${NC} $1"; }
fail() { echo -e "${RED}✘${NC} $1"; exit 1; }

[[ "$EUID" -ne 0 ]] && fail "Execute como root: sudo bash deploy_ckan.sh"

# Cria diretório e entra
mkdir -p "$APP_DIR"
cd "$APP_DIR"

msg "Criando arquivo .env com valores padrão..."
cat > "$ENV_FILE" <<'EOF'
# Host Ports
CKAN_PORT_HOST=5000

# Databases
POSTGRES_USER=ckan_default
POSTGRES_PASSWORD=pass
POSTGRES_DB=ckan_default
CKAN_DB_USER=ckan_default
CKAN_DB_PASSWORD=pass
CKAN_DB=ckan_default
DATASTORE_READONLY_USER=datastore_ro
DATASTORE_READONLY_PASSWORD=datastore
DATASTORE_DB=datastore

CKAN_SQLALCHEMY_URL=postgresql://ckan_default:pass@db/ckan_default
CKAN_DATASTORE_WRITE_URL=postgresql://ckan_default:pass@db/datastore
CKAN_DATASTORE_READ_URL=postgresql://datastore_ro:datastore@db/datastore?application_name=readonly

# CKAN core
CKAN_SITE_URL=http://localhost:5000
CKAN___BEAKER__SESSION__SECRET=$(openssl rand -hex 32)
CKAN___API_TOKEN__JWT__ENCODE__SECRET=string:$(openssl rand -hex 32)
CKAN___API_TOKEN__JWT__DECODE__SECRET=string:$(openssl rand -hex 32)
CKAN_SYSADMIN_NAME=ckan_admin
CKAN_SYSADMIN_PASSWORD=admin1234
CKAN_SYSADMIN_EMAIL=admin@example.com
CKAN_STORAGE_PATH=/var/lib/ckan
CKAN_MAX_UPLOAD_SIZE_MB=100
TZ=America/Sao_Paulo

# Services
CKAN_SOLR_URL=http://solr:8983/solr/ckan
CKAN_REDIS_URL=redis://redis:6379/1
CKAN__PLUGINS="image_view text_view datatables_view datastore envvars"
EOF

msg "Criando docker-compose.yml..."
cat > "$COMPOSE_FILE" <<'EOF'
services:
  db:
    image: postgres:16-alpine
    container_name: ckan-db
    restart: unless-stopped
    environment:
      TZ: ${TZ}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 20
    networks:
      - ckan

  redis:
    image: redis:7-alpine
    container_name: ckan-redis
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 20
    networks:
      - ckan

  solr:
    image: ckan/ckan-solr:2.10-solr9
    container_name: ckan-solr
    restart: unless-stopped
    user: "8983:8983"
    volumes:
      - solr_data:/var/solr
    healthcheck:
      test: ["CMD", "wget", "-qO", "/dev/null", "http://localhost:8983/solr/ckan/admin/ping"]
      interval: 30s
      timeout: 15s
      retries: 20
      start_period: 60s
    networks:
      - ckan

  ckan:
    image: ckan/ckan-base:2.10.4
    container_name: ckan-app
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
      solr:
        condition: service_healthy
    ports:
      - "${CKAN_PORT_HOST}:5000"
    environment:
      - TZ=${TZ}
      - CKAN_SQLALCHEMY_URL=${CKAN_SQLALCHEMY_URL}
      - CKAN_DATASTORE_WRITE_URL=${CKAN_DATASTORE_WRITE_URL}
      - CKAN_DATASTORE_READ_URL=${CKAN_DATASTORE_READ_URL}
      - CKAN_SOLR_URL=${CKAN_SOLR_URL}
      - CKAN_REDIS_URL=${CKAN_REDIS_URL}
      - CKAN_SITE_URL=${CKAN_SITE_URL}
      - CKAN___BEAKER__SESSION__SECRET=${CKAN___BEAKER__SESSION__SECRET}
      - CKAN___API_TOKEN__JWT__ENCODE__SECRET=${CKAN___API_TOKEN__JWT__ENCODE__SECRET}
      - CKAN___API_TOKEN__JWT__DECODE__SECRET=${CKAN___API_TOKEN__JWT__DECODE__SECRET}
      - CKAN_SYSADMIN_NAME=${CKAN_SYSADMIN_NAME}
      - CKAN_SYSADMIN_PASSWORD=${CKAN_SYSADMIN_PASSWORD}
      - CKAN_SYSADMIN_EMAIL=${CKAN_SYSADMIN_EMAIL}
      - CKAN_STORAGE_PATH=${CKAN_STORAGE_PATH}
      - CKAN_MAX_UPLOAD_SIZE_MB=${CKAN_MAX_UPLOAD_SIZE_MB}
      - CKAN__PLUGINS=${CKAN__PLUGINS}
    volumes:
      - ckan_storage:/var/lib/ckan
    networks:
      - ckan

networks:
  ckan:
    driver: bridge

volumes:
  postgres_data:
  solr_data:
  ckan_storage:
EOF

msg "Inicializando containers..."
docker compose --env-file "$ENV_FILE" down --remove-orphans 2>/dev/null || true
docker compose --env-file "$ENV_FILE" up -d

msg "Aguardando CKAN iniciar (até 2 minutos)..."
sleep 10
for i in {1..30}; do
  if curl -fsS "http://localhost:${CKAN_PORT_HOST}" >/dev/null 2>&1; then
    ok "CKAN está respondendo!"
    break
  fi
  sleep 5
done

msg "Executando ckan db init dentro do container..."
docker exec ckan-app ckan db init 2>/dev/null || docker exec ckan-app bash -c "source /usr/lib/ckan/venv/bin/activate && ckan db init"

ok "Deploy concluído!"
echo
echo "===================================================="
echo " CKAN disponível em: http://localhost:${CKAN_PORT_HOST}"
echo " Admin: ${CKAN_SYSADMIN_NAME} / ${CKAN_SYSADMIN_PASSWORD}"
echo " Diretório: ${APP_DIR}"
echo " Logs: docker compose logs -f ckan"
echo "===================================================="
EOFii

chmod +x deploy_ckan.sh

sudo ./deploy_ckan.sh
