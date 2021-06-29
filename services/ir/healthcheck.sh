#!/bin/sh

EXPECTED="Health status: READY"
GOT=`/neofs-cli -r $NEOFS_IR_CONTROL_GRPC_ENDPOINT --binary-key /wallet01.key control healthcheck --ir | grep Health`
if [ "$EXPECTED" = "$GOT" ]; then exit 0; else exit 1; fi
