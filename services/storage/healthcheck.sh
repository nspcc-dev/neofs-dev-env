#!/bin/sh

/neofs-cli control healthcheck \
	--endpoint "$NEOFS_CONTROL_GRPC_ENDPOINT" \
	--binary-key "$NEOFS_NODE_KEY" |
	grep "Health status: READY"
