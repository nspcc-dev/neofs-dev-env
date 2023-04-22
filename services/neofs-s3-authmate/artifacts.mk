# Download neofs-s3-authmate to deploy test environment

# Download neofs-s3-authmate binaries
get.neofs-s3-authmate: S3_GW_DEST=./vendor
get.neofs-s3-authmate: S3_AUTHMATE_BIN=neofs-s3-authmate
get.neofs-s3-authmate: S3_GW_BIN=neofs-s3-gw
get.neofs-s3-authmate:
	@mkdir -p ${S3_GW_DEST}

ifeq (${S3_GW_PATH},)
	@echo "⇒ Download compiled neofs-s3-authmate from ${S3_AUTHMATE_URL}"
	@curl -sSL ${S3_AUTHMATE_URL} -o ${S3_GW_DEST}/${S3_AUTHMATE_BIN}
	@echo "⇒ Download compiled neofs-s3-gw from ${S3_GW_URL}"
	@curl -sSL ${S3_GW_URL} -o ${S3_GW_DEST}/${S3_GW_BIN}
else
	@echo "⇒ Copy compiled neofs-s3-authmate and from ${S3_GW_PATH}"
	@cp -r ${S3_GW_PATH}/* ${S3_GW_DEST}
endif
	@chmod +x ${S3_GW_DEST}/${S3_AUTHMATE_BIN}
	@chmod +x ${S3_GW_DEST}/${S3_GW_BIN}
