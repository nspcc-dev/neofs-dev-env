#!/usr/bin/env bash

echo "Running bin/tick.sh"

# Source env settings
. .env
. services/ir/.ir.env
source bin/helper.sh

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec main_chain neo-go}"

# Wallet files to change config value
WALLET="${WALLET:-services/chain/node-wallet.json}"
CONFIG_IMG="${CONFIG_IMG:-/wallets/config.yml}"

# Internal variables
if [[ -z "${NEOFS_NOTARY_DISABLED}" ]]; then
  ADDR=$(jq -r .accounts[1].address < "${WALLET}" || die "Cannot get address from ${WALLET}")
else
  ADDR=$(jq -r .accounts[0].address < "${WALLET}" || die "Cannot get address from ${WALLET}")
fi

# Grep NeoFS chain block time
NEOFS_CHAIN_PROTO="${NEOFS_CHAIN_PROTO:-services/ir/cfg/config.yml}"
BLOCK_DURATION=$(grep time_per_block < "$NEOFS_CHAIN_PROTO" | awk '{print $2}') \
	|| die "Cannot fetch block duration"
NETMAP_ADDR=$(bin/resolve.sh netmap.neofs) || die "Cannot resolve netmap.neofs"

# Fetch current epoch value
EPOCH=$(${NEOGO} contract testinvokefunction \
	-r "http://ir01.${LOCAL_DOMAIN}:30333" "${NETMAP_ADDR}" epoch \
	| grep 'value' | awk -F'"' '{ print $4 }') \
	|| die "Cannot fetch epoch from netmap contract"

echo "Updating NeoFS epoch to $((EPOCH+1))"

# shellcheck disable=SC2086
${NEOGO} contract invokefunction \
        --wallet-config ${CONFIG_IMG} \
	-a ${ADDR} --force --await \
	-r http://ir01.${LOCAL_DOMAIN}:30333 \
	${NETMAP_ADDR} \
	newEpoch int:$((EPOCH+1)) -- ${ADDR}:Global \
        || die "Cannot increment an epoch"
