# Create new tls certs

NATS_DIR=$(abspath services/nats)

get.nats:
	@echo "⇒ Creating certs for NATS server and clients"
	${NATS_DIR}/generate_cert.sh ${LOCAL_DOMAIN}
