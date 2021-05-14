#!/usr/bin/env bash

# Source env settings
. .env
. services/ir/.ir.env

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it main_chain neo-go}"

# Wallet files to change config value 
WALLET="${WALLET:-services/chain/node-wallet.json}"
WALLET_IMG="${WALLET_IMG:-wallets/node-wallet.json}"

# NeoFS configuration record: key is a string and value is an int
KEY=${1}
VALUE="${2}"

[ -z "$KEY" ] && echo "Empty config key" && exit 1
[ -z "$VALUE" ] && echo "Empty config value" && exit 1

# Internal variables
ADDR=`cat ${WALLET} | jq -r .accounts[2].address`

# Change config value in side chain
echo "Changing ${KEY} configration value to ${VALUE}"
${NEOGO} contract invokefunction \
-w ${WALLET_IMG} \
-a ${ADDR} \
-r http://morph_chain.${LOCAL_DOMAIN}:30333 \
${NEOFS_IR_CONTRACTS_NETMAP} \
setConfig bytes:beefcafe \
string:${KEY} \
int:${VALUE} -- ${ADDR} || exit 1

# Fetch current epoch value
EPOCH=`${NEOGO} contract testinvokefunction -r \
http://morph_chain.${LOCAL_DOMAIN}:30333 \
${NEOFS_IR_CONTRACTS_NETMAP} \
epoch | grep 'value' | awk -F'"' '{ print $4 }'`

# Update epoch to apply new configuartion value
echo "Updating NeoFS epoch to $((EPOCH+1))"
${NEOGO} contract invokefunction \
-w ${WALLET_IMG} \
-a ${ADDR} \
-r http://morph_chain.${LOCAL_DOMAIN}:30333 \
${NEOFS_IR_CONTRACTS_NETMAP} \
newEpoch int:$((EPOCH+1)) -- ${ADDR}:Global
