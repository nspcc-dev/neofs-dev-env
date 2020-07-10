get.chain: JF_TOKEN?=
get.chain: CHAIN_DUMP_NAME=devenv.dump.
get.chain: CHAIN_PATH?=
get.chain:
	@mkdir -p ./vendor

ifeq (${CHAIN_PATH},)
	@echo "⇒ Download blockchain dump VERSION=${CHAIN_VERSION}"
	@curl \
		-sS "https://cdn.fs.neo.org/5iZZi4HzXpk3xjHa2ahi8RCrVae74Q7487ns5ms7S2EF/a488ff1a-6339-404c-8360-456005445032" \
		-o ./vendor/chain.gz
else
	@echo "⇒ Copy local archive ${CHAIN_PATH}"
	@cp ${CHAIN_PATH} ./vendor/chain.gz
endif
