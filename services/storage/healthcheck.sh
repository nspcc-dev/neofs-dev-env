#!/bin/sh

/neofs-cli control healthcheck \
	--endpoint "$NEOFS_CONTROL_GRPC_ENDPOINT" \
	--wallet "$NEOFS_NODE_KEY" |
	grep "Health status: READY"
