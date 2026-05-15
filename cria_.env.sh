

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
