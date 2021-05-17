#!/usr/bin/env bash

# Source env settings
. .env
. services/ir/.ir.env

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it main_chain neo-go}"
# Wallet file to use for deposit GAS from
WALLET="${WALLET:-wallets/wallet.json}"
# How much GAS to deposit. First cli argument or 50 by default
DEPOSIT="${1:-50}"

# Internal variables
ADDR=`cat ${WALLET} | jq -r .accounts[0].address`
CONTRACT_ADDR=`${NEOGO} util convert ${NEOFS_IR_CONTRACTS_NEOFS} | grep 'LE ScriptHash to Address' | awk '{print $5}' | grep -oP [A-z0-9]+`

# Make deposit
${NEOGO} wallet nep17 transfer \
-w ${WALLET} \
-r http://main_chain.${LOCAL_DOMAIN}:30333 \
--from ${ADDR} \
--to ${CONTRACT_ADDR} \
--token GAS \
--amount ${DEPOSIT}
