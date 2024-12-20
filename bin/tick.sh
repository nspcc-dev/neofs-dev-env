#!/usr/bin/env bash

echo "Running bin/tick.sh"

# Source env settings
. .env
source bin/helper.sh

# NeoADM binary path and config path.
NEOADM="${NEOADM:-./vendor/neofs-adm}"
CONFIG_ADM="${CONFIG_ADM:-./neofs-adm.yml}"

${NEOADM} fschain force-new-epoch --alphabet-wallets services/ir${IR_NUMBER_OF_NODES}/alphabet \
  -r http://ir01.${LOCAL_DOMAIN}:30333 -c ${CONFIG_ADM}
