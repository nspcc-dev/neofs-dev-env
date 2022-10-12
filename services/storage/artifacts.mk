# Create new TLS certs to NeoFS node

CURRENT_DIR=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
STORAGE_DIR=$(patsubst %/,%,$(CURRENT_DIR))
SSL_CONFIG=$(shell mktemp)

get.storage:
	@echo "⇒ Creating TLS certs to NeoFS node"
	@(echo "[req]"; \
      echo "distinguished_name=req"; \
      echo "req_extensions=san"; \
      echo "[san]"; \
      echo "subjectAltName=DNS:s04.${LOCAL_DOMAIN}") > ${SSL_CONFIG}
	@echo $(test -e "${STORAGE_DIR}/s04tls.key" && echo true)
	@if [ ! -e "${STORAGE_DIR}/s04tls.key" ]; then \
		openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
		-subj "/C=RU/ST=SPB/L=St.Petersburg/O=NSPCC/OU=NSPCC/CN=s04.${LOCAL_DOMAIN}" \
		-keyout "${STORAGE_DIR}/s04tls.key" -out "${STORAGE_DIR}/s04tls.crt" \
		-extensions san -config "${SSL_CONFIG}" ; \
		fi
