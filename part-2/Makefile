default: all

SHELL := /bin/bash
CURRENT_DIR := $(shell cd -P -- '$(shell dirname -- "$0")' && pwd -P)

all: lint lint2 build clair
 
lint:
	@echo "Apply hadolint to Dockerfile ..."
	@docker run --rm -i hadolint/hadolint < Dockerfile

lint2:
	@echo "Apply dockerfile-lint to Dockerfile ..."
	@docker run -it --rm -v $(CURRENT_DIR):/root/ projectatomic/dockerfile-lint dockerfile_lint -r policies/rules.yml 

build: 
	@echo "Building Hugo Builder container..."
	@docker build -t lp/hugo-builder .
	@echo "Hugo Builder container built!"
	@docker images lp/hugo-builder

hugo:
	@echo "Invoke hugo compiler ..."
	@docker run -it --rm --name hugo-server --volume ${CURRENT_DIR}/orgdocs:/src lp/hugo-builder ash -c 'hugo'

start: 
	@echo "Starting application ..."
	@docker run --rm -d --name hugo-server -p 1313:1313 --volume ${CURRENT_DIR}/orgdocs:/src lp/hugo-builder ash -c 'hugo server -w --bind=0.0.0.0'
	
stop:
	@echo "Stopping application ..." 
	@docker stop hugo-server

health:
	@echo "Checking health of OrgDocs Hugo site..."
	@docker inspect --format='{{json .State.Health}}' hugo-server
	@echo "Health check complete!"

clair:  start-clair clair-scanner stop-clair

clair-scanner: start-clair
	@docker run --rm --name "scanner" --net=docker-container-security_clairnet -v /var/run/docker.sock:/var/run/docker.sock objectiflibre/clair-scanner --clair="http://clair:6060" --ip="scanner" lp/hugo-builder:latest

start-clair:
	@echo "Starting clair server ..."
	@docker-compose up -d
	@echo "waiting for some seconds ..."
	@sleep 5

stop-clair:
	@echo "Shutting down clair server ..."
	@docker-compose down
.PHONY: build start
