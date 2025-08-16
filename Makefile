################################################################################
# Makefile for HostIT (Foundry)
#
# Usage examples:
#   make help                 # show all commands
#   make build                # compile contracts
#   make test                 # run all tests
#   make test V=vvvv          # increase verbosity
#   make test TEST=Factory    # run tests matching name
#   make test-file FILE=test/Factory.t.sol  # run a specific file
#   make gas                  # run tests with gas report
#   make coverage             # run coverage
#   make fmt                  # format solidity files
#   make fmt-check            # check formatting (no changes)
#   make anvil                # start a local chain
#   make deploy               # deploy via forge script (needs RPC_URL & ACCOUNT)
#   make simulate             # simulate script (no broadcast)
#   make clean                # clean build artifacts
################################################################################

# Load environment variables
include .env

# Set default goal to help
.DEFAULT_GOAL := help

# Tools
FORGE ?= forge
CAST  ?= cast
ANVIL ?= anvil

# Configuration
FOUNDRY_PROFILE ?= default

# Script / Deploy variables (override via environment or inline: make deploy RPC_URL=...)
SCRIPT ?= script/DeployHostIt.s.sol
RPC_URL ?= http://127.0.0.1:8545
ACCOUNT ?= mainKey
SENDER ?= $(WALLET_ADDR)

# Test selection
TEST ?=
FILE ?=

.PHONY: help build test test-file t gas snapshot coverage fmt fmt-check anvil deploy-pk deploy simulate clean

## Show this help
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nAvailable targets:\n\n"} /^[a-zA-Z0-9_.-]+:.*##/ { printf "  \033[36m%-18s\033[0m %s\n", $$1, $$2 } /^## / { sub(/^## /, ""); print "\n" $$0 "\n" } ' $(MAKEFILE_LIST)

## Build contracts
build:
	$(FORGE) build

## Run tests (set TEST=name_substr to filter by test name)
test:
	@if [ -n "$(TEST)" ]; then \
		$(FORGE) test -vvvv --match-test $(TEST); \
	else \
		$(FORGE) test -v$${V:-vv}; \
	fi

## Run a specific test file: make test-file FILE=test/Factory.t.sol
test-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Please provide FILE=<path to *.t.sol>"; exit 1; \
	fi; \
	$(FORGE) test -v$${V:-vv} --match-path $(FILE)

## Run all tests and display failed tests trace
t:
	$(FORGE) t -vvvvv -s

## Run tests with gas report
gas:
	$(FORGE) test -v$${V:-vv} --gas-report

## Create gas snapshots
snapshot:
	$(FORGE) snapshot

## Run coverage
coverage:
	$(FORGE) coverage -v

## Format solidity files
fmt:
	$(FORGE) fmt

## Format solidity files continuously
fmt-w:
	$(FORGE) fmt -w

## Check formatting (no changes)
fmt-check:
	$(FORGE) fmt --check

## Start local Anvil chain
anvil:
	$(ANVIL)

## Deploy using forge script (requires RPC_URL and PRIVATE_KEY)
deploy-pk:
	@if [ -z "$(RPC_URL)" ] || [ -z "$(PRIVATE_KEY)" ]; then \
		echo "RPC_URL and PRIVATE_KEY must be set. Example:"; \
		echo "  make deploy RPC_URL=https://.. PRIVATE_KEY=0x8b69.."; \
		exit 1; \
	fi; \
	$(FORGE) script $(SCRIPT) \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast -vvvv

## Deploy and verify using forge script (requires RPC_URL and ACCOUNT)
deploy:
	@if [ -z "$(RPC_URL)" ] || [ -z "$(ACCOUNT)" ]; then \
		echo "RPC_URL and ACCOUNT must be set. Example:"; \
		echo "make deploy-verify RPC_URL=$(RPC_URL).. ACCOUNT=mainKey.. SENDER=0x.. VERIFIER=blockscout"; \
		exit 1; \
	fi; \
	$(FORGE) script $(SCRIPT) \
		--rpc-url $(RPC_URL) \
		--account $(ACCOUNT) \
		--sender $(SENDER) \
		--broadcast -vvvv \
		--verifier $(VERIFIER) \
		--verifier-url $(VERIFIER_URL)

## Simulate script without broadcasting (no PRIVATE_KEY / ACCOUNT required)
simulate:
	$(FORGE) script $(SCRIPT) --rpc-url $(RPC_URL) -vvvv

## Clean build artifacts
clean:
	$(FORGE) clean