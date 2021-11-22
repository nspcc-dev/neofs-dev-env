#!/usr/bin/env bash

# Source env settings
. .env
. services/ir/.ir.env

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it main_chain neo-go}"
# Wallet file to use for deposit GAS from
WALLET="${WALLET:-wallets/wallet.json}"
S3WALLET="${S3WALLET:-services/s3_gate/wallet.json}"
# Wallet password that would be entered automatically; '-' means no password
PASSWD="-"
S3PASSWD="s3"
# How much GAS to deposit. First cli argument or 50 by default
DEPOSIT="${1:-50}"

# Internal variables
ADDR=`cat ${WALLET} | jq -r .accounts[0].address`
S3ADDR=`cat ${S3WALLET} | jq -r .accounts[0].address`
CONTRACT_ADDR=`${NEOGO} util convert ${NEOFS_IR_CONTRACTS_NEOFS} | grep 'LE ScriptHash to Address' | awk '{print $5}' | grep -oP [A-z0-9]+`

# Transfer assets from main wallet to s3 wallet
./bin/passwd.exp ${PASSWD} ${NEOGO} wallet nep17 transfer \
-w ${WALLET} \
-r http://main_chain.${LOCAL_DOMAIN}:30333 \
--from ${ADDR} \
--to ${S3ADDR} \
--token GAS \
--amount ${DEPOSIT}

# Waiting one morph block for transaction to persist
sleep 1s

# Make deposit
./bin/passwd.exp ${S3PASSWD} ${NEOGO} wallet nep17 transfer \
-w ${S3WALLET} \
-r http://main_chain.${LOCAL_DOMAIN}:30333 \
--from ${S3ADDR} \
--to ${CONTRACT_ADDR} \
--token GAS \
--amount ${DEPOSIT}
