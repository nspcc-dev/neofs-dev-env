#!/usr/bin/env bash

# Source env settings
. .env

ln -sf $(pwd)/services/storage/s04tls.crt ${CA_CERTS_TRUSTED_STORE}/s04.${LOCAL_DOMAIN}.tls.crt
