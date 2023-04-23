# Get NeoFS IR artifacts (LOCODE database and NeoFS CLI)

LOCODE_DB_ARCHIVE_PATH=./vendor
LOCODE_DB_ARCHIVE_FILE=locode_db.gz

get.ir: get.locode get.cli

# Get NeoFS LOCODE database
get.locode: LOCODE_DB_PATH?= 
get.locode:
	@mkdir -p ${LOCODE_DB_ARCHIVE_PATH}

ifeq (${LOCODE_DB_PATH},)
	@echo "⇒ Download NeoFS LOCODE database from ${LOCODE_DB_URL}"
	@curl \
		-sSL "${LOCODE_DB_URL}" \
		-o ${LOCODE_DB_ARCHIVE_PATH}/${LOCODE_DB_ARCHIVE_FILE}
else
	@echo "⇒ Copy local archive of NeoFS LOCODE database from ${LOCODE_DB_PATH}"
	@cp ${LOCODE_DB_PATH} ${LOCODE_DB_ARCHIVE_PATH}/${LOCODE_DB_ARCHIVE_FILE}
endif

	gzip -dfk ${LOCODE_DB_ARCHIVE_PATH}/${LOCODE_DB_ARCHIVE_FILE}

# Download NeoFS CLI 
.ONESHELL:
get.cli: NEOFS_CLI_FILE=./vendor/neofs-cli
get.cli: NEOFS_CLI_ARCHIVE_FILE=${NEOFS_CLI_FILE}.tar.gz
get.cli: NEOFS_CLI_PATH?=
get.cli:
	@mkdir -p ./vendor

ifeq (${NEOFS_CLI_PATH},)
    ifneq (${NEOFS_CLI_URL},)
		@echo "⇒ Download NeoFS CLI binary from ${NEOFS_CLI_URL}"
		@curl \
		    -sSL "${NEOFS_CLI_URL}" \
		    -o ${NEOFS_CLI_ARCHIVE_FILE}
		@tar -xvf ${NEOFS_CLI_ARCHIVE_FILE} -C ./vendor | xargs -I {} \
			mv ./vendor/{} ${NEOFS_CLI_FILE}
		@rm ${NEOFS_CLI_ARCHIVE_FILE}
    else
	    @echo "⇒ NEOFS_CLI_PATH and NEOFS_CLI_URL are empty."
    endif
else
    ifneq (${NEOFS_CLI_PATH},)
		@echo "⇒ Copy local binary from ${NEOFS_CLI_PATH}"
		@cp ${NEOFS_CLI_PATH} ${NEOFS_CLI_FILE}
    else
		@echo "⇒ NEOFS_CLI_PATH is empty."
    endif
endif
