#!/bin/sh

EXPECTED="Health status: READY"
GOT=`/neofs-cli -r $NEOFS_CONTROL_GRPC_ENDPOINT --binary-key $NEOFS_NODE_KEY control healthcheck | grep "Health"`
if [ "$EXPECTED" = "$GOT" ]; then exit 0; else exit 1; fi
