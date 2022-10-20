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
START_SVCS = $(shell cat .services | grep -v \\\#)
START_BASIC = $(shell cat .basic_services | grep -v \\\#)
START_BOOTSTRAP = $(shell cat .bootstrap_services | grep -v \\\#)
STOP_SVCS = $(shell tac .services | grep -v \\\#)
STOP_BASIC = $(shell tac .basic_services | grep -v \\\#)
STOP_BOOTSTRAP = $(shell tac .bootstrap_services | grep -v \\\#)

# Enabled services dirs
ENABLED_SVCS_DIRS = $(shell echo "${START_BOOTSTRAP} ${START_BASIC} ${START_SVCS}" | sed 's|[^ ]* *|./services/&|g')

# Services that require artifacts
GET_SVCS = $(shell grep -Rl "get.*:" ./services/* | sort -u | grep artifacts.mk | xargs -I {} dirname {} | xargs basename -a)

# Services that require pulling images
PULL_SVCS = $(shell find ${ENABLED_SVCS_DIRS} -type f -name 'docker-compose.yml' | sort -u | xargs -I {} dirname {} | xargs basename -a)

# List of hosts available in devenv
HOSTS_LINES = $(shell grep -Rl IPV4_PREFIX ./services/* | grep .hosts)

# Paths to protocol.privnet.yml
MORPH_CHAIN_PROTOCOL = './services/morph_chain/protocol.privnet.yml'
CHAIN_PROTOCOL = './services/chain/protocol.privnet.yml'

# List of grepped environment variables from *.env
GREP_DOTENV = $(shell find . -name '*.env' -exec grep -rhv -e '^\#' -e '^$$' {} + | sort -u )

# Pull all required Docker images
.PHONY: pull
pull:
	$(foreach SVC, $(PULL_SVCS), $(shell cd services/$(SVC) && docker-compose pull))
	@:

# Get all services artifacs
.PHONY: get
get: $(foreach SVC, $(GET_SVCS), get.$(SVC))
	@:

# Start environment
.PHONY: up
up: up/basic
	@$(foreach SVC, $(START_SVCS), $(shell docker-compose -f services/$(SVC)/docker-compose.yml up -d))
	@echo "Full NeoFS Developer Environment is ready"

# Build up NeoFS
.PHONY: up/basic
up/basic: up/bootstrap
	@$(foreach SVC, $(START_BASIC), $(shell docker-compose -f services/$(SVC)/docker-compose.yml up -d))
	@./bin/tick.sh
	@./bin/config.sh string SystemDNS container
	@echo "Basic NeoFS Developer Environment is ready"

# Start bootstrap services
.PHONY: up/bootstrap
up/bootstrap: get vendor/hosts
	@$(foreach SVC, $(START_BOOTSTRAP), $(shell docker-compose -f services/$(SVC)/docker-compose.yml up -d))
	@./vendor/neofs-adm --config neofs-adm.yml morph init --alphabet-wallets ./services/ir --contracts vendor/contracts || exit 1
	@for f in ./services/storage/wallet*.json; do echo "Transfer GAS to wallet $${f}" && ./vendor/neofs-adm -c neofs-adm.yml morph refill-gas --storage-wallet $${f} --gas 10.0 --alphabet-wallets services/ir || exit 1; done
	@echo "NeoFS sidechain environment is deployed"

# Build up certain service
.PHONY: up/%
up/%: get vendor/hosts
	@docker-compose -f services/$*/docker-compose.yml up -d
	@echo "Developer Environment for $* service is ready"

# Stop environment
.PHONY: down
down: down/add down/basic down/bootstrap
	@echo "Full NeoFS Developer Environment is down"

.PHONY: down/add
down/add:
	$(foreach SVC, $(STOP_SVCS), $(shell docker-compose -f services/$(SVC)/docker-compose.yml down))

# Stop basic environment
.PHONY: down/basic
down/basic:
	$(foreach SVC, $(STOP_BASIC), $(shell docker-compose -f services/$(SVC)/docker-compose.yml down))

# Stop bootstrap services
.PHONY: down/bootstrap
down/bootstrap:
	$(foreach SVC, $(STOP_BOOTSTRAP), $(shell docker-compose -f services/$(SVC)/docker-compose.yml down))

# Stop certain service
.PHONY: down/%
down/%:
	@docker-compose -f services/$*/docker-compose.yml down

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

# Display changes for /etc/hosts
.PHONY: hosts
hosts: vendor/hosts
	@cat vendor/hosts

# Clean-up the environment
.PHONY: clean
.ONESHELL:
clean:
	@rm -rf vendor/* services/storage/s04tls.* services/nats/*.pem
	@> .int_test.env
	@for svc in $(PULL_SVCS)
	do
		vols=`docker-compose -f services/$${svc}/docker-compose.yml config --volumes`
		if [[ ! -z "$${vols}" ]]; then
			for vol in $${vols}; do
				docker volume rm -f "$${svc}_$${vol}" 2> /dev/null
			done
		fi
	done

# Generate environment
.PHONY: env
env:
	@$(foreach envvar,$(GREP_DOTENV),echo $(envvar);)
	@echo MORPH_BLOCK_TIME=$(shell grep 'SecondsPerBlock' $(MORPH_CHAIN_PROTOCOL) | awk '{print $$2}')s
	@echo MAINNET_BLOCK_TIME=$(shell grep 'SecondsPerBlock' $(CHAIN_PROTOCOL) | awk '{print $$2}')s
	@echo MORPH_MAGIC=$(shell grep 'Magic' $(MORPH_CHAIN_PROTOCOL) | awk '{print $$2}')

# Restart storage nodes with clean volumes
.PHONY: restart.storage-clean
restart.storage-clean:
	@docker-compose -f ./services/storage/docker-compose.yml down
	@$(foreach vol, \
		$(shell docker-compose -f services/storage/docker-compose.yml config --volumes),\
		docker volume rm storage_$(vol);)
	@docker-compose -f ./services/storage/docker-compose.yml up -d

