#!/usr/bin/env bash

# Source env settings
. .env
. services/ir/.ir.env

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it main_chain neo-go}"
# Launching neo-go this way is useful, when running the script not from
# terminal, for instance, in jenkins job.
NEOGO_NONINTERACTIVE="${NEOGO_NONINTERACTIVE:-docker exec main_chain neo-go}"

# Wallet files to change config value
WALLET="${WALLET:-services/chain/node-wallet.json}"
WALLET_IMG="${WALLET_IMG:-wallets/node-wallet.json}"

# Wallet password that would be entered automatically; '-' means no password
PASSWD="one"

# Internal variables
if [[ -z "${NEOFS_NOTARY_DISABLED}" ]]; then
  ADDR=`cat ${WALLET} | jq -r .accounts[2].address`
else
  ADDR=`cat ${WALLET} | jq -r .accounts[0].address`
fi

# Grep Morph block time
SIDECHAIN_PROTO="${SIDECHAIN_PROTO:-services/morph_chain/protocol.privnet.yml}"
BLOCK_DURATION=`grep SecondsPerBlock < $SIDECHAIN_PROTO | awk '{print $2}'`

# Fetch current epoch value
EPOCH=`${NEOGO_NONINTERACTIVE} contract testinvokefunction -r \
http://morph_chain.${LOCAL_DOMAIN}:30333 \
${NEOFS_IR_CONTRACTS_NETMAP} \
epoch | grep 'value' | awk -F'"' '{ print $4 }'`

echo "Updating NeoFS epoch to $((EPOCH+1))"
./bin/passwd.exp ${PASSWD} ${NEOGO} contract invokefunction \
-w ${WALLET_IMG} \
-a ${ADDR} \
-r http://morph_chain.${LOCAL_DOMAIN}:30333 \
${NEOFS_IR_CONTRACTS_NETMAP} \
newEpoch int:$((EPOCH+1)) -- ${ADDR}:Global

# Wait one Morph block to ensure the transaction broadcasted
sleep $BLOCK_DURATION
