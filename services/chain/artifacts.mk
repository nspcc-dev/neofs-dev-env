get.chain: JF_TOKEN?=
get.chain: CHAIN_DUMP_NAME=devenv.dump.
get.chain: CHAIN_PATH?=
get.chain:
	@mkdir -p ./vendor

ifeq (${CHAIN_PATH},)
	@echo "⇒ Download blockchain dump VERSION=${CHAIN_VERSION}"
	@curl \
		-sS "https://cdn.fs.neo.org/5iZZi4HzXpk3xjHa2ahi8RCrVae74Q7487ns5ms7S2EF/cfa4e687-30c7-4456-abe8-02cfc131c6b1" \
		-o ./vendor/chain.gz
else
	@echo "⇒ Copy local archive ${CHAIN_PATH}"
	@cp ${CHAIN_PATH} ./vendor/chain.gz
endif
