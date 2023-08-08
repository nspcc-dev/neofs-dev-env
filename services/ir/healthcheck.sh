#!/bin/sh

out=$(/neofs-cli control healthcheck -c /cli-cfg.yml \
      	--endpoint "$NEOFS_IR_CONTROL_GRPC_ENDPOINT" \
      	--ir)

echo "$out"

if [[ "$out" == *"Health status: READY"* ]]; then
  exit 0
else
   exit 1
fi
