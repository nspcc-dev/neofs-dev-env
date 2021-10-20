#!/bin/sh

/neofs-cli control healthcheck \
	--endpoint "$NEOFS_IR_CONTROL_GRPC_ENDPOINT" \
	--binary-key /wallet01.key --ir |
	grep "Health status: READY"
