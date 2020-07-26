get.chain: JF_TOKEN?=
get.chain: CHAIN_DUMP_NAME=devenv.dump.
get.chain: CHAIN_PATH?=
get.chain:
	@mkdir -p ./vendor

ifeq (${CHAIN_PATH},)
	@echo "⇒ Download blockchain dump VERSION=${CHAIN_VERSION}"
	@curl \
		-sS "https://fs.neo.org/dist/chain.gz" \
		-o ./vendor/chain.gz
else
	@echo "⇒ Copy local archive ${CHAIN_PATH}"
	@cp ${CHAIN_PATH} ./vendor/chain.gz
endif
