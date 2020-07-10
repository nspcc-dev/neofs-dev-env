#!/usr/bin/make -f
SHELL := bash

include .env
-include .secrets

include help.mk

# Get
include services/*/artifacts.mk

# Services that require artifacts
GET_SVCS = $(shell grep -Rl "get.*:" ./services/* | sort -u | grep artifacts.mk | xargs -I {} dirname {} | xargs basename -a)

# Services that require pulling images
PULL_SVCS = $(shell find ./services -type f -name 'docker-compose.yml' | sort -u | xargs -I {} dirname {} | xargs basename -a)

# Sorted services for running
START_SVCS = $(shell find ./services -type f -name '.order' | xargs -I % /bin/bash -c 'echo "$$(cat %) %"' | sort -u | awk '{ print $$2 }' | xargs -I {} dirname {} | xargs basename -a)
STOP_SVCS = $(shell find ./services -type f -name '.order' | xargs -I % /bin/bash -c 'echo "$$(cat %) %"' | sort -ur | awk '{ print $$2 }' | xargs -I {} dirname {} | xargs basename -a)

# List of available sites
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

# Build custom environments
.PHONY: rebuild
rebuild: $(foreach SVC, $(BUILD_SVCS), build.$(SVC))
	@:

# Start environments
.PHONY: up
up: get
	$(foreach SVC, $(START_SVCS), $(shell docker-compose -f services/$(SVC)/docker-compose.yml up -d))
	@:

# Stop environments
.PHONY: down
down:
	$(foreach SVC, $(STOP_SVCS), $(shell docker-compose -f services/$(SVC)/docker-compose.yml down))
	@:

# Display changes for /etc/hosts
.PHONY: hosts
hosts:
	@for file in $(HOSTS_LINES); do \
		while read h; do \
			echo $${h} | sed 's|IPV4_PREFIX|$(IPV4_PREFIX)|g'; \
		done < $${file}; \
	done
