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
LESH=`${NEOGO} util convert ${ADDR} | grep 'Address to LE ScriptHash' | awk '{print $5}' | grep -oP [A-z0-9]+`

# Make deposit
${NEOGO} contract invokefunction \
-w ${WALLET} \
-a ${ADDR} \
-r http://main_chain.${LOCAL_DOMAIN}:30333 \
${NEOFS_IR_CONTRACTS_NEOFS} \
deposit ${LESH} \
int:${DEPOSIT} \
bytes: -- ${LESH}:Global
