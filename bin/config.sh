#!/usr/bin/env bash

# Source env settings
. .env
. services/ir/.ir.env

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it main_chain neo-go}"

# Wallet files to change config value
WALLET="${WALLET:-services/chain/node-wallet.json}"
WALLET_IMG="${WALLET_IMG:-wallets/node-wallet.json}"
# Wallet password that would be entered automatically; '-' means no password
PASSWD="one"
NETMAP_ADDR=`bin/resolve.sh netmap.neofs`

# NeoFS configuration record: variable type [string|int|etc],
# key is a string and value is a constant of given type
TYPE=${1}
KEY=${2}
VALUE="${3}"

[ -z "$TYPE" ] && echo "Empty config value type" && exit 1
[ -z "$KEY" ] && echo "Empty config key" && exit 1
[ -z "$VALUE" ] && echo "Empty config value" && exit 1

# Internal variables
if [[ -z "${NEOFS_NOTARY_DISABLED}" ]]; then
  ADDR=`cat ${WALLET} | jq -r .accounts[2].address`
else
  ADDR=`cat ${WALLET} | jq -r .accounts[0].address`
fi

# Change config value in side chain
echo "Changing ${KEY} configration value to ${VALUE}"
./bin/passwd.exp ${PASSWD} ${NEOGO} contract invokefunction \
-w ${WALLET_IMG} \
-a ${ADDR} \
-r http://morph_chain.${LOCAL_DOMAIN}:30333 \
${NETMAP_ADDR} \
setConfig bytes:beefcafe \
string:${KEY} \
${TYPE}:${VALUE} -- ${ADDR} || exit 1

# Update epoch to apply new configuration value
./bin/tick.sh
