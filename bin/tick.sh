#!/usr/bin/env bash

# Source env settings
. .env
. services/ir/.ir.env
source bin/helper.sh

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it main_chain neo-go}"

# Wallet files to change config value
WALLET="${WALLET:-services/chain/node-wallet.json}"
WALLET_IMG="${WALLET_IMG:-wallets/node-wallet.json}"

# Wallet password that would be entered automatically; '-' means no password
PASSWD="one"

# Internal variables
if [[ -z "${NEOFS_NOTARY_DISABLED}" ]]; then
  ADDR=$(jq -r .accounts[2].address < "${WALLET}" || die "Cannot get address from ${WALLET}")
else
  ADDR=$(jq -r .accounts[0].address < "${WALLET}" || die "Cannot get address from ${WALLET}")
fi

# Grep Morph block time
SIDECHAIN_PROTO="${SIDECHAIN_PROTO:-services/morph_chain/protocol.privnet.yml}"
BLOCK_DURATION=$(grep SecondsPerBlock < "$SIDECHAIN_PROTO" | awk '{print $2}') \
	|| die "Cannot fetch block duration"
NETMAP_ADDR=$(bin/resolve.sh netmap.neofs) || die "Cannot resolve netmap.neofs"

# Fetch current epoch value
EPOCH=$(${NEOGO} contract testinvokefunction \
	-r "http://morph-chain.${LOCAL_DOMAIN}:30333" "${NETMAP_ADDR}" epoch \
	| grep 'value' | awk -F'"' '{ print $4 }') \
	|| die "Cannot fetch epoch from netmap contract"

echo "Updating NeoFS epoch to $((EPOCH+1))"

# shellcheck disable=SC2086
./bin/passwd.exp ${PASSWD} ${NEOGO} contract invokefunction \
	-w ${WALLET_IMG} \
	-a ${ADDR} \
	-r http://morph-chain.${LOCAL_DOMAIN}:30333 \
	${NETMAP_ADDR} \
	newEpoch int:$((EPOCH+1)) -- ${ADDR}:Global

# Wait one Morph block to ensure the transaction broadcasted
# shellcheck disable=SC2086
sleep $BLOCK_DURATION
