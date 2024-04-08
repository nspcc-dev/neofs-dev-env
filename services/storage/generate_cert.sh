#!/bin/bash

source bin/helper.sh

WORKDIR=$(dirname "$0")
LOCAL_DOMAIN=$1
SSL_CONFIG=$(mktemp)
CERT="${WORKDIR}/s04tls.crt"
KEY="${WORKDIR}/s04tls.key"


if [[ ! -f ${CERT} ]]; then
        (
            echo "[req]"; \
            echo "distinguished_name=req"; \
            echo "req_extensions=san"; \
            echo "[san]"; \
            echo "subjectAltName=DNS:s04.${LOCAL_DOMAIN}"
        ) > ${SSL_CONFIG}

        openssl req -new -newkey rsa:4096 -x509 -sha256 -days 365 -nodes \
        -subj "/C=RU/ST=SPB/L=St.Petersburg/O=NSPCC/OU=NSPCC/CN=s04.${LOCAL_DOMAIN}" \
        -keyout "${KEY}" -out "${CERT}" -extensions san -config "${SSL_CONFIG}" &> /dev/null || {
            rm ${SSL_CONFIG}
            die "Failed to generate SSL certificate for s04"
        }
        rm ${SSL_CONFIG}
fi
