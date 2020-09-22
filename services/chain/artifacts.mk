get.chain: CHAIN_DUMP_NAME=devenv.dump.
get.chain: CHAIN_PATH?=
get.chain:
	@mkdir -p ./vendor

ifeq (${CHAIN_PATH},)
	@echo "⇒ Download blockchain dump from ${CHAIN_URL}"
	@curl \
		-sS "${CHAIN_URL}" \
		-o ./vendor/chain.gz
else
	@echo "⇒ Copy local archive ${CHAIN_PATH}"
	@cp ${CHAIN_PATH} ./vendor/chain.gz
endif


