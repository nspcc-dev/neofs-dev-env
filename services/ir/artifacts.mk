# Get NeoFS LOCODE database

LOCODE_DB_ARCHIVE_PATH=./vendor
LOCODE_DB_ARCHIVE_FILE=locode_db.gz

get.ir: LOCODE_DB_PATH?=
get.ir:
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
