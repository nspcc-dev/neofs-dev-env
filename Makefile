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
MORPH_CHAIN_PROTOCOL = './services/morph_chain/protocol.privnet.yml'
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
	@for svc in $(START_BOOTSTRAP); do \
		echo "$@ for service: $${svc}"; \
		docker-compose -f services/$${svc}/docker-compose.yml up -d 2>&1 | tee -a docker-compose.err; \
	done
	@source ./bin/helper.sh
	@./vendor/neofs-adm --config neofs-adm.yml morph init --alphabet-wallets ./services/ir --contracts vendor/contracts || die "Failed to initialize Alphabet wallets"
	@for f in ./services/storage/wallet*.json; do echo "Transfer GAS to wallet $${f}" && ./vendor/neofs-adm -c neofs-adm.yml morph refill-gas --storage-wallet $${f} --gas 10.0 --alphabet-wallets services/ir || die "Failed to transfer GAS to alphabet wallets"; done
	$(call error_handler,$@);
	@echo "NeoFS sidechain environment is deployed"

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
	@rm -rf vendor/* services/storage/s04tls.* services/nats/*.pem
	@> .int_test.env
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
	@echo MORPH_BLOCK_TIME=$(shell grep 'TimePerBlock' $(MORPH_CHAIN_PROTOCOL) | awk '{print $$2}')
	@echo MAINNET_BLOCK_TIME=$(shell grep 'TimePerBlock' $(CHAIN_PROTOCOL) | awk '{print $$2}')
	@echo MORPH_MAGIC=$(shell grep 'Magic' $(MORPH_CHAIN_PROTOCOL) | awk '{print $$2}')

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

# Test Environment Preparation Target
.PHONY: prepare-test-env
prepare-test-env:
	@echo "Starting the test environment setup..."

	trap 'echo "Test environment setup failed. Please check the error messages above."; exit 1;' ERR

	echo "Step 1: Setting up the test environment..."; \
	$(MAKE) up; \
#	Why 524288? Amazon S3 multipart min upload limits is 5 MiB: https://docs.aws.amazon.com/AmazonS3/latest/userguide/qfacts.html
#	In tests, we test aws and create a lot of tets objects.
#	This "magic" constant was chosen as a compromise for the speed of tests and for the possibility to cover aws multipart functionality.
	./bin/config.sh int MaxObjectSize 524288; \
	echo "Waiting a few seconds..."; \
	sleep 30; \

	echo "Step 3: Preparing the IR service..."; \
	$(MAKE) prepare.ir; \
	sleep 10; \

	echo "Step 4: Preparing the storage service..."; \
	$(MAKE) prepare.storage; \

	echo "Test environment setup completed."
