SHELL := /usr/bin/env bash
.PHONY: install

BOLD_BIN := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/bin)

install:
	@printf 'Run this in your shell to add bold to your PATH:\n'
	@printf '\n'
	@printf '  export PATH="$(BOLD_BIN):$$PATH"\n'
	@printf '\n'
	@printf 'Then: bold help\n'
