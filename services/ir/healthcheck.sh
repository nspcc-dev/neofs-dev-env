#!/bin/sh

/neofs-cli control healthcheck \
	--endpoint "$NEOFS_IR_CONTROL_GRPC_ENDPOINT" \
	--wallet /wallet01.key --ir |
	grep "Health status: READY"
