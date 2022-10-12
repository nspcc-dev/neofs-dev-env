# Download NeoFS Contracts and Adm tool to deploy environment

get.morph_chain: get.contracts get.adm

# Download NeoFS Contracts
get.contracts: NEOFS_CONTRACTS_DEST=./vendor/contracts
get.contracts: NEOFS_CONTRACTS_ARCHIVE=neofs-contracts.tar.gz
get.contracts:
	@mkdir -p ${NEOFS_CONTRACTS_DEST}

ifeq (${NEOFS_CONTRACTS_PATH},)
	@echo "⇒ Download compiled NeoFS contracts from ${NEOFS_CONTRACTS_URL}"
	@curl -sSL ${NEOFS_CONTRACTS_URL} -o ${NEOFS_CONTRACTS_ARCHIVE}
	@tar -xf ${NEOFS_CONTRACTS_ARCHIVE} -C ${NEOFS_CONTRACTS_DEST} --strip-components 1 
	@rm ${NEOFS_CONTRACTS_ARCHIVE}
else
	@echo "⇒ Copy compiled contracts from ${NEOFS_CONTRACTS_PATH}"
	@cp -r ${NEOFS_CONTRACTS_PATH}/* ${NEOFS_CONTRACTS_DEST}
endif

# Download NeoFS ADM tool 
get.adm: NEOFS_ADM_DEST=./vendor/neofs-adm
get.adm: NEOFS_ADM_ARCHIVE=neofs-adm.tar.gz
get.adm:

ifeq (${NEOFS_ADM_PATH},)
	@echo "⇒ Download NeoFS ADM binary from ${NEOFS_ADM_URL}"
	@curl -sSL ${NEOFS_ADM_URL} -o ${NEOFS_ADM_ARCHIVE}
	@tar -xvf ${NEOFS_ADM_ARCHIVE} -C ./vendor | xargs -I {} \
		mv ./vendor/{} ${NEOFS_ADM_DEST}
	@rm ${NEOFS_ADM_ARCHIVE}
else
	@echo "⇒ Copy neofs-adm binary from ${NEOFS_ADM_PATH}"
	@cp ${NEOFS_ADM_PATH} ${NEOFS_ADM_DEST}
endif
