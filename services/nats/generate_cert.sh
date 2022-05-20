#!/bin/bash

WORKDIR=$(dirname "$0")
LOCAL_DOMAIN=$1

CA_KEY=$WORKDIR/ca-key.pem
CA_CRT=$WORKDIR/ca-cert.pem

SRV_KEY=$WORKDIR/server-key.pem
SRV_REQ=$WORKDIR/server-req.csr
SRV_CRT=$WORKDIR/server-cert.pem

CLI_KEY=$WORKDIR/client-key.pem
CLI_REQ=$WORKDIR/client-req.csr
CLI_CRT=$WORKDIR/client-cert.pem

SUBJ="/O=NSPCC"

if [[ ! -f $CA_KEY || ! -f $CA_CRT ]]; then
	OUT=$(openssl req -newkey rsa:4096 -x509 -days 365 -nodes -keyout $CA_KEY -out $CA_CRT -subj $SUBJ 2>&1) || {
		echo "CA certificate was not created"
		echo $OUT
		exit 1
	}
fi

if [[ ! -f $SRV_KEY || ! -f $SRV_CRT ]]; then
	OUT=$(openssl req -newkey rsa:4096 -nodes -keyout $SRV_KEY -out $SRV_REQ -subj $SUBJ 2>&1 ) || {
		echo "Server certificate was not created"
		echo $OUT
		exit 1
	}

	OUT=$(openssl x509 -req -days 365 -set_serial 01 -in $SRV_REQ -out $SRV_CRT -CA $CA_CRT -CAkey $CA_KEY \
 		-extensions san -extfile <(printf "[san]\nsubjectAltName=DNS:nats.$LOCAL_DOMAIN") 2>&1)|| {
		echo "Server certificate was not signed by CA"
		echo $OUT
		rm $SRV_REQ
		exit 1
	}

	rm $SRV_REQ
fi

if [[ ! -f $CLI_KEY || ! -f $CLI_CRT ]]; then
	OUT=$(openssl req -newkey rsa:4096 -nodes -keyout $CLI_KEY -out $CLI_REQ -subj $SUBJ 2>&1) || {
		echo "Client certificate was not created"
		echo $OUT
		exit 1
	}

	OUT=$(openssl x509 -req -days 365 -set_serial 01 -in $CLI_REQ -out $CLI_CRT -CA $CA_CRT -CAkey $CA_KEY 2>&1) || {
		echo "Client certificate was not signed by CA"
		echo $OUT
		rm $CLI_REQ
		exit 1
	}

	rm $CLI_REQ
fi
