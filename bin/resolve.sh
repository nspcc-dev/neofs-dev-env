#!/usr/bin/env bash

# Source env settings
. .env

# NeoGo binary path.
NEOGO="${NEOGO:-docker exec -it morph_chain neo-go}"
# NNS contract script hash
NNS_ADDR=`curl -s --data '{ "id": 1, "jsonrpc": "2.0", "method": "getcontractstate", "params": [1] }' http://morph_chain.${LOCAL_DOMAIN}:30333/ | jq -r '.result.hash'`

${NEOGO} contract testinvokefunction \
-r http://morph_chain.${LOCAL_DOMAIN}:30333 \
${NNS_ADDR} resolve string:${1} int:16 | jq -r '.stack[0].value | if type=="array" then .[0].value else . end' | base64 -d
