# Download NeoFS sidechain dump with pre-deployed NeoFS contracts
get.morph_chain: MORPH_CHAIN_DUMP_NAME=neo.morph.dump.
get.morph_chain: MORPH_CHAIN_PATH?=
get.morph_chain:
	@mkdir -p ./vendor

ifeq (${MORPH_CHAIN_PATH},)
	@echo "⇒ Download morph chain dump from ${MORPH_CHAIN_URL}"
	@curl \
		-sS "${MORPH_CHAIN_URL}" \
		-o ./vendor/morph_chain.gz
else
	@echo "⇒ Copy local archive ${MORPH_CHAIN_PATH}"
	@cp ${MORPH_CHAIN_PATH} ./vendor/morph_chain.gz
endif
