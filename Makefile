#!/usr/bin/make -f
SHELL = bash

# Main environment configuration
include .env

# Optional variables with secrests
-include .secrets

# help target
include help.mk

# Targets to get required artifacts and external resources for each service
include services/*/artifacts.mk

# Targets helpful to prepare service environment
include services/*/prepare.mk

# Services that require artifacts
GET_SVCS = $(shell grep -Rl "get.*:" ./services/* | sort -u | grep artifacts.mk | xargs -I {} dirname {} | xargs basename -a)

# Services that require pulling images
PULL_SVCS = $(shell find ./services -type f -name 'docker-compose.yml' | sort -u | xargs -I {} dirname {} | xargs basename -a)

# List of services to run
START_SVCS = $(shell cat .services | grep -v \\\#)
STOP_SVCS = $(shell tac .services | grep -v \\\#)

# List of hosts available in devenv
HOSTS_LINES = $(shell grep -Rl IPV4_PREFIX ./services/* | grep .hosts)


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
up: pull get vendor/hosts
	$(foreach SVC, $(START_SVCS), $(shell docker-compose -f services/$(SVC)/docker-compose.yml up -d))

# Stop environment
.PHONY: down
down:
	$(foreach SVC, $(STOP_SVCS), $(shell docker-compose -f services/$(SVC)/docker-compose.yml down))

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

# Clean-up the envirinment
.PHONY: clean
.ONESHELL:
clean:
	@rm -rf vendor/*
	@for svc in $(START_SVCS)
	do
		vols=`docker-compose -f services/$${svc}/docker-compose.yml config --volumes`
		if [[ ! -z "$${vols}" ]]; then
			for vol in $${vols}; do
				docker volume rm "$${svc}_$${vol}" 2> /dev/null
			done
		fi
	done
