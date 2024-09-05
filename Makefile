#!/usr/bin/make -f
SHELL = bash

# Main environment configuration
include .env

# Optional variables with secrets
-include .secrets

# help target
include help.mk

# update NeoFS global config targets
include neofs_config.mk

# Targets to get required artifacts and external resources for each service
include services/*/artifacts.mk

# Targets helpful to prepare service environment
include services/*/prepare.mk

# List of services to run
START_SVCS = $(shell cat .services | grep -v '\#')
START_BASIC = $(shell cat .basic_services | grep -ve '\#')
START_BOOTSTRAP = $(shell cat .bootstrap_services | grep -v '\#')
STOP_SVCS = $(shell tac .services | grep -v '\#')
STOP_BASIC = $(shell tac .basic_services | grep -v '\#')
STOP_BOOTSTRAP = $(shell tac .bootstrap_services | grep -v '\#')

# Enabled services dirs
ENABLED_SVCS_DIRS = $(shell echo "${START_BOOTSTRAP} ${START_BASIC} ${START_SVCS}" | sed 's|[^ ]* *|./services/&|g')

# Services that require artifacts
GET_SVCS = $(shell grep -Rl "get.*:" ./services/* | sort -u | grep artifacts.mk | xargs -I {} dirname {} | xargs basename -a)

# Services that require pulling images
PULL_SVCS = $(shell find ${ENABLED_SVCS_DIRS} -type f -name 'docker-compose.yml' | sort -u | xargs -I {} dirname {} | xargs basename -a)

# List of hosts available in devenv
HOSTS_LINES = $(shell grep -Rl IPV4_PREFIX ./services/* | grep .hosts)

# Paths to protocol.privnet.yml
NEOFS_CHAIN_PROTOCOL = './services/ir/cfg/config.yml'
CHAIN_PROTOCOL = './services/chain/protocol.privnet.yml'

# List of grepped environment variables from *.env
GREP_DOTENV = $(shell find . -name '*.env' -exec grep -rhv -e '^\#' -e '^$$' {} + | sort -u )

# Error handling function
define error_handler
    ret_val=$$?;\
	if [ "$$ret_val" -ne 0 ]; then \
		cat docker-compose.err;\
		echo "Error: The target $1 failed with exit code $$ret_val";\
		rm docker-compose.err;\
		exit "$$ret_val";\
	fi;\
	if grep -q "ERROR" docker-compose.err; then \
		cat docker-compose.err;\
		echo "Error: The target '$1' failed and exit code is $$ret_val";\
		rm docker-compose.err;\
		exit 1;\
	else \
		echo "The target '$1' completed successfully";\
		rm docker-compose.err;\
		exit 0;\
	fi
endef

# Pull all required Docker images
.PHONY: pull
pull:
	@for svc in $(PULL_SVCS); do \
		echo "$@ for service: $${svc}"; \
		docker-compose -f services/$${svc}/docker-compose.yml pull 2>&1 | tee -a docker-compose.err; \
	done
	$(call error_handler,$@);
	@:

# Get all services artifacts
.PHONY: get
get:
	@for svc in $(GET_SVCS); do \
		echo "$@ for service: $${svc}"; \
		make get.$$svc 2>&1 | tee -a docker-compose.err; \
	done
	$(call error_handler,$@);
	@:

# Start environment
.PHONY: up
up: up/basic
	@for svc in $(START_SVCS); do \
		echo "$@ for service: $${svc}"; \
		docker-compose -f services/$${svc}/docker-compose.yml up -d 2>&1 | tee -a docker-compose.err; \
	done
	$(call error_handler,$@);
	@echo "Full NeoFS Developer Environment is ready"

# Build up NeoFS
.PHONY: up/basic
up/basic: up/bootstrap
	@for svc in $(START_BASIC); do \
		echo "$@ for service: $${svc}"; \
		docker-compose -f services/$${svc}/docker-compose.yml up -d 2>&1 | tee -a docker-compose.err; \
	done
	@./bin/tick.sh
	@./bin/config.sh string SystemDNS container
	$(call error_handler,$@);
	@echo "Basic NeoFS Developer Environment is ready"

# Start bootstrap services
.PHONY: up/bootstrap
up/bootstrap: get vendor/hosts
	@echo "NEOFS_IR_CONTRACTS_NEOFS="`./vendor/neo-go contract calc-hash -s NbUgTSFvPmsRxmGeWpuuGeJUoRoi6PErcM --in vendor/contracts/neofs/contract.nef -m vendor/contracts/neofs/manifest.json | grep -Eo '[a-fA-F0-9]{40}'` > services/ir/.ir.env
	@for svc in $(START_BOOTSTRAP); do \
		echo "$@ for service: $${svc}"; \
		docker-compose -f services/$${svc}/docker-compose.yml up -d 2>&1 | tee -a docker-compose.err; \
	done
	@source ./bin/helper.sh
	@docker exec main_chain neo-go wallet nep17 transfer --force --await --wallet-config /wallets/config.yml -r http://main-chain.neofs.devenv:30333 --from NfgHwwTi3wHAS8aFAN243C5vGbkYDpqLHP  --to NbUgTSFvPmsRxmGeWpuuGeJUoRoi6PErcM --token GAS --amount 1000
	@./vendor/neo-go contract deploy --wallet-config wallets/config.yml --in vendor/contracts/neofs/contract.nef --manifest vendor/contracts/neofs/manifest.json --force --await -r http://main-chain.neofs.devenv:30333 [ true ffffffffffffffffffffffffffffffffffffffff [ 02b3622bf4017bdfe317c58aed5f4c753f206b7db896046fa7d774bbc4bf7f8dc2 ] [ InnerRingCandidateFee 10000000000 WithdrawFee 100000000 ] ]
	@NEOGO=vendor/neo-go WALLET=wallets/wallet.json CONFIG=wallets/config.yml ./bin/deposit.sh
	@for f in ./services/storage/wallet*.json; do echo "Transfer GAS to wallet $${f}" && ./vendor/neofs-adm -c neofs-adm.yml morph refill-gas --storage-wallet $${f} --gas 10.0 --alphabet-wallets services/ir || die "Failed to transfer GAS to alphabet wallets"; done
	$(call error_handler,$@);
	@echo "NeoFS chain environment is deployed"

# Build up certain service
.PHONY: up/%
up/%: get vendor/hosts
	@docker-compose -f services/$*/docker-compose.yml up -d 2>&1 | tee -a docker-compose.err
	$(call error_handler,$@);
	@echo "Developer Environment for $* service is ready"

# Stop environment
.PHONY: down
down: down/add down/basic down/bootstrap
	@echo "Full NeoFS Developer Environment is down"

.PHONY: down/add
down/add:
	@for svc in $(STOP_SVCS); do \
		echo "$@ for service: $${svc}"; \
		docker-compose -f services/$${svc}/docker-compose.yml down 2>&1 | tee -a docker-compose.err; \
	done
	$(call error_handler,$@);

# Stop basic environment
.PHONY: down/basic
down/basic:
	@for svc in $(STOP_BASIC); do \
		echo "$@ for service: $${svc}"; \
		docker-compose -f services/$${svc}/docker-compose.yml down 2>&1 | tee -a docker-compose.err; \
	done
	$(call error_handler,$@);

# Stop bootstrap services
.PHONY: down/bootstrap
down/bootstrap:
	@for svc in $(STOP_BOOTSTRAP); do \
		echo "$@ for service: $${svc}"; \
		docker-compose -f services/$${svc}/docker-compose.yml down 2>&1 | tee docker-compose.err; \
	done
	$(call error_handler,$@);

# Stop certain service
.PHONY: down/%
down/%:
	@docker-compose -f services/$*/docker-compose.yml down 2>&1 | tee docker-compose.err
	$(call error_handler,$@);

# Generate changes for /etc/hosts
.PHONY: vendor/hosts
.ONESHELL:
vendor/hosts:
	@for file in $(HOSTS_LINES)
	do
		while read h
		do
			echo $${h} | \
			sed 's|IPV4_PREFIX|$(IPV4_PREFIX)|g' | \
			sed 's|LOCAL_DOMAIN|$(LOCAL_DOMAIN)|g'
		done < $${file};
	done > $@

# Generate and display changes for /etc/hosts
.PHONY: hosts
hosts: vendor/hosts
	@cat vendor/hosts

# Clean-up the environment
.PHONY: clean
.ONESHELL:
clean:
	@rm -rf vendor/* services/storage/s04tls.* services/k6_node/id_ed25519*
	@for svc in $(PULL_SVCS)
	do
		vols=`docker-compose -f services/$${svc}/docker-compose.yml config --volumes 2>&1 | tee -a docker-compose.err`
		if [[ ! -z "$${vols}" ]]; then
			for vol in $${vols}; do
				docker volume rm -f "$${svc}_$${vol}" 2> /dev/null
			done
		fi
	done
	$(call error_handler,$@);

# Generate environment
.PHONY: env
env:
	@$(foreach envvar,$(GREP_DOTENV),echo $(envvar);)
	@echo NEOFS_CHAIN_BLOCK_TIME=$(shell grep 'time_per_block' $(NEOFS_CHAIN_PROTOCOL) | awk '{print $$2}')
	@echo MAINNET_BLOCK_TIME=$(shell grep 'TimePerBlock' $(CHAIN_PROTOCOL) | awk '{print $$2}')
	@echo NEOFS_CHAIN_MAGIC=$(shell grep 'magic' $(NEOFS_CHAIN_PROTOCOL) | awk '{print $$2}')

# Restart storage nodes with clean volumes
.PHONY: restart.storage-clean
restart.storage-clean:
	@docker-compose -f ./services/storage/docker-compose.yml down 2>&1 | tee -a docker-compose.err
	@$(foreach vol, \
		$(shell docker-compose -f services/storage/docker-compose.yml config --volumes 2>&1 | tee -a docker-compose.err),\
		$(call error_handler,$@ for storage_$${vol}); \,\
		docker volume rm storage_$(vol);)
	docker-compose -f ./services/storage/docker-compose.yml up -d 2>&1 | tee -a docker-compose.err
	$(call error_handler,$@);
