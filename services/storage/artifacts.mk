# Create new tls certs

STORAGE_DIR=$(patsubst %/,%,$(dir $(abspath $(lastword $(MAKEFILE_LIST)))))
SSL_CONFIG := $(shell mktemp)

get.storage:
	@echo "⇒ Creating tls certs to NeoFS node"
	@(echo "[req]"; \
      echo "distinguished_name=req"; \
      echo "req_extensions=san"; \
      echo "[san]"; \
      echo "subjectAltName=DNS:s04.${LOCAL_DOMAIN}") > ${SSL_CONFIG}
ifeq ($(shell ! test -e ${STORAGE_DIR}/s04tls.key && echo -n yes),yes)
	@openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
    		-subj "/C=RU/ST=SPB/L=St.Petersburg/O=NSPCC/OU=NSPCC/CN=s04.${LOCAL_DOMAIN}" \
    		-keyout ${STORAGE_DIR}/s04tls.key -out ${STORAGE_DIR}/s04tls.crt -extensions san -config ${SSL_CONFIG}
endif
