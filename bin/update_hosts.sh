#!/usr/bin/env bash
set -e

: "${HOSTS_FILE:=/etc/hosts}"
: "${NEOFS_CHAIN_CONFIG:=services/ir/cfg/config.yml}"
temp_file=$(mktemp)

# Get default hosts
make hosts > "$temp_file"

# Get the NeoFS chain IP address from the hosts file
neofs_chain_ip=$(grep "ir01.neofs.devenv" "$temp_file" | awk '{print $1}')

# Get NeoFS chain listeners by full YAML path.
listen_addresses=$(
  python3 -c 'import json, sys, yaml; print(json.dumps(yaml.safe_load(open(sys.argv[1], "r", encoding="utf-8"))))' "$NEOFS_CHAIN_CONFIG" \
    | jq -r '.fschain.consensus.rpc.listen[], .fschain.consensus.p2p.listen[]'
)

for listen_address in $listen_addresses; do
  if [[ "$listen_address" =~ :([0-9]+)$ ]]; then
    updated_listen_address="${neofs_chain_ip}:${BASH_REMATCH[1]}"
    listen_address_escaped=${listen_address//./\\.}
    sed -i "s|$listen_address_escaped|$updated_listen_address|" "$NEOFS_CHAIN_CONFIG"
  fi
done

while IFS=" " read -r ip domain; do
  updated=false

  # Check if the domain starts with "*", and if so, escape it for use in regex
  if [[ "${domain:0:1}" == "*" ]]; then
    domain_escaped="\\${domain}"
  else
    domain_escaped="${domain//./\\.}"
  fi

  # Check if the IP and domain pair already exists in the hosts file
  if grep -Eq "^(([0-9]{1,3}[.]){3}[0-9]{1,3})[[:space:]]+${domain_escaped}$" "$HOSTS_FILE"; then
    existing_ip=$(grep -Eo "^(([0-9]{1,3}[.]){3}[0-9]{1,3})[[:space:]]+${domain_escaped}$" "$HOSTS_FILE" | awk '{print $1}')
    
    # If the IP addresses don't match, update the entry in the hosts file
    if [[ "$existing_ip" != "$ip" ]]; then
      sed -i -r "s/(([0-9]{1,3}[.]){3}[0-9]{1,3})[[:space:]]+${domain_escaped}/$ip $domain/" "$HOSTS_FILE"
      updated=true
    fi
  else
    # If the IP and domain pair doesn't exist in the hosts file, append it
    echo "$ip $domain" >> "$HOSTS_FILE"
    echo "Added: $ip $domain"
  fi
  
  # Print an update message if an entry has been updated
  if [[ "$updated" = true ]]; then
    echo "Updated: $ip $domain"
  fi
done < "$temp_file"

rm "$temp_file"
