efault: all

SHELL := /bin/bash
CURRENT_DIR := $(shell cd -P -- '$(shell dirname -- "$0")' && pwd -P)
BUILD_DATE := $(shell date -u +'%Y-%m-%dT%H:%M:%SZ')
REVISION := $(shell git rev-parse --short HEAD)
VERSION := $(shell git tag --points-at HEAD --list)
IMAGE := "lp/hugo-builder"

all: lint lint2 build clair

clean:
	rm -rf ${CURRENT_DIR}/tmp
 
lint:
	@echo "Apply hadolint to Dockerfile ..."
	@docker run --rm -i hadolint/hadolint < Dockerfile

lint2:
	@echo "Apply dockerfile-lint to Dockerfile ..."
	@docker run -it --rm -v $(CURRENT_DIR):/root/ projectatomic/dockerfile-lint dockerfile_lint -r policies/rules.yml 

build: 
	@echo "Building Hugo Builder container..." $(BUILD_DATE) 
	@docker build -t lp/hugo-builder --no-cache=true \
		--build-arg BUILD_DATE=$(BUILD_DATE) \
		--build-arg REVISION=$(REVISION) \
 		--build-arg VERSION=$(VERSION) \
		--build-arg IMAGE=$(IMAGE) \
		.
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

build-tern:
	mkdir -p ${CURRENT_DIR}/tmp
	rm -rf ${CURRENT_DIR}/tmp/tern
	@cd tmp
	@git clone https://github.com/tern-tools/tern
	cd ${CURRENT_DIR}/tmp/tern
	docker build . -t ternd

tern:
	@echo "using tern to build spdx report"
	mkdir -p ${CURRENT_DIR}/tmp ${CURRENT_DIR}/tmp/workdir
	@docker run --privileged \
	   -v /var/run/docker.sock:/var/run/docker.sock \
	   --mount type=bind,source=${CURRENT_DIR}/tmp/workdir,target=/hostmount \
	   --rm \
	   ternd report \
	      --report-format spdxtagvalue \
	      --docker-image lp/hugo-builder:latest \
	      > hugo-builder.spdx

notary_key:
	@echo "create root key:"
	@echo "shell> docker trust key generate markus --dir ~/.docker/trust"
	@echo ""
	notary -d ~/.docker/trust key list

notary_sign: build
	DOCKER_CONTENT_TRUST=1
	docker tag lp/hugo-builder docker.io/bfblog/hugo-builder:1.5.0
	docker login --username bfblog
	docker push docker.io/bfblog/hugo-builder:1.5.0
	docker pull docker.io/bfblog/hugo-builder:1.5.0
	docker trust signer add --key ~/.docker/trust/markus.pub markus docker.io/bfblog/hugo-builder:1.5.0
	docker trust inspect --pretty docker.io/bfblog/hugo-builder


.PHONY: build start tern
