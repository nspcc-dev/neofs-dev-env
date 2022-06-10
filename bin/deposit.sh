#!/usr/bin/env bash

# Source env settings
. .env
. services/ir/.ir.env
source bin/helper.sh

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it main_chain neo-go}"
# Wallet file to use for deposit GAS from
WALLET="${WALLET:-wallets/wallet.json}"
# Wallet password that would be entered automatically; '-' means no password
PASSWD="-"
# How much GAS to deposit. First cli argument or 50 by default
DEPOSIT="${1:-50}"

# Internal variables
ADDR=$(jq -r .accounts[0].address < "${WALLET}" \
	|| die "Cannot get address from wallet: ${WALLET}")
CONTRACT_ADDR=$(${NEOGO} util convert "${NEOFS_IR_CONTRACTS_NEOFS}" \
	| grep 'LE ScriptHash to Address' \
	| awk '{print $5}' \
	| grep -oP "[A-z0-9]+" \
	|| die "Cannot parse contract address: ${NEOFS_IR_CONTRACTS_NEOFS}")

# Make deposit
# shellcheck disable=SC2086
./bin/passwd.exp ${PASSWD} ${NEOGO} wallet nep17 transfer \
	-w ${WALLET} \
	-r http://main-chain.${LOCAL_DOMAIN}:30333 \
	--from ${ADDR} \
	--to ${CONTRACT_ADDR} \
	--token GAS \
	--amount ${DEPOSIT}
