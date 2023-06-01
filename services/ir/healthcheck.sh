#!/bin/sh

/neofs-cli control healthcheck -c /cli-cfg.yml \
	--endpoint "$NEOFS_IR_CONTROL_GRPC_ENDPOINT" \
	--ir |
	grep "Health status: READY"
