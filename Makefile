default: build

SHELL=/bin/ash -eo pipefail
CURRENT_DIR := $(SHELL pwd)
 
hadolint:
	@echo "Apply lint to Dockerfile ..."
	@docker run --rm -i hadolint/hadolint < Dockerfile

build: hadolint
	@echo "Building Hugo Builder container..."
	@docker build -t lp/hugo-builder .
	@echo "Hugo Builder container built!"
	@docker images lp/hugo-builder

hugo:
	@echo "Invoke hugo compiler ..."
	@docker run -it --rm --volume ${CURRENT_DIR}/orgdocs:/src lp/hugo-builder ash -c 'hugo'

start: 
	@echo "Starting application ..."
	@docker run -it --name hugo-server -p 1313:1313 --volume ${CURRENT_DIR}/orgdocs:/src lp/hugo-builder ash -c 'hugo server -w --bind=0.0.0.0'
	
stop:
	@echo "Stopping application ..." 
	@docker stop hugo-server

health:
	@echo "Checking health of OrgDocs Hugo site..."
	@docker inspect --format='{{json .State.Health}}' hugo-server
	@echo "Health check complete!"

.PHONY: build start
