default: all

SHELL := /bin/bash
CURRENT_DIR := $(shell cd -P -- '$(shell dirname -- "$0")' && pwd -P)

all: lint build
 
lint:
	@echo "Apply lint to Dockerfile ..."
	@docker run --rm -i hadolint/hadolint < Dockerfile

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

.PHONY: build start
