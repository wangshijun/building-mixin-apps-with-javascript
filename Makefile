TOP_DIR=.
OUTPUT_FOLDER=./dist

VERSION=$(strip $(shell cat version))

build:
	@cd src; gitbook-cli build
	@echo "All slides are built."

init:
	@npm install -g gitbook-cli
	@npm install

travis-init: init
	@echo "Initialize software required for travis (normally ubuntu software)"

clean:
	@rm -rf dist
	@echo "All slides are cleaned."

$(OUTPUT_FOLDER):
	@mkdir -p $@

dev:
	@cd src; gitbook-cli serve
run:
	@http-server $(OUTPUT_FOLDER) -p 8008 -c-1

travis-deploy: release
	@echo "Deploy the software by travis"

.PHONY: all clean $(DIRS) build run watch
