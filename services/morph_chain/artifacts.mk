get.morph_chain: JF_TOKEN?=
get.morph_chain: MORPH_CHAIN_DUMP_NAME=neo.morph.dump.
get.morph_chain: MORPH_CHAIN_PATH?=
get.morph_chain:
	@mkdir -p ./vendor

ifeq (${MORPH_CHAIN_PATH},)
	@echo "⇒ Download morph chain dump VERSION=${MORPH_CHAIN_VERSION}"
	@curl \
		-sS "https://cdn.fs.neo.org/5iZZi4HzXpk3xjHa2ahi8RCrVae74Q7487ns5ms7S2EF/2d066e4c-de65-4184-9f8d-4d9216d9965f" \
		-o ./vendor/morph_chain.gz
else
	@echo "⇒ Copy local archive ${MORPH_CHAIN_PATH}"
	@cp ${MORPH_CHAIN_PATH} ./vendor/morph_chain.gz
endif
