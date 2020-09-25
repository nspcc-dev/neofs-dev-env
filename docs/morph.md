# NeoFS sidechain service

It's a single-node Neo3-based NeoFS sidechain deployment running on
[neo-go](https://github.com/nspcc-dev/neo-go).

## .env settings

### MORPH_CHAIN_URL="https://fs.neo.org/dist/neo.morph.gz"

URL to get NeoFS sidechain dump. Used on artifact get stage.

### MORPH_CHAIN_PATH

Path to get NeoFS sidechain chain dump. If set, overrides `MORPH_CHAIN_URL`.

### NEOGO_VERSION=0.91.0-6-gd7e13de5

Version on NeoGo container to use in both main privnet and sidechain.
