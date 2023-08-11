#!/usr/bin/env bash
KEY=services/k6_node/id_ed25519

if [[ ! -f $KEY ]]; then
    ssh-keygen -b 2048 -t ed25519 -f $KEY -q -N ""
fi
