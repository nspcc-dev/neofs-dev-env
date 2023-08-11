K6_NODE_DIR=$(abspath services/k6_node)

get.k6_node:
	@echo "⇒ Creating keys for k6 node server and clients"
	${K6_NODE_DIR}/generate_keys.sh > /dev/null
