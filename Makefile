# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)
#
# Multi-repo commit helper.
# This Makefile commits all configured repositories with the same message.
# It uses `git -C` so you can run it from anywhere, and it skips repos with
# no staged changes. Extend REPOS to add more repositories under the root.
#
# Usage:
#   make commit-all msg="your message"

REPOS ?= bms-core bms-meta
ROOT := $(abspath $(dir $(lastword $(MAKEFILE_LIST)))/..)
REPO_DIRS := $(addprefix $(ROOT)/,$(REPOS))

.PHONY: commit-all
commit-all:
	@msg="$(msg)"; \
	if [ -z "$$msg" ]; then \
		echo "msg is required (example: make commit-all msg=\"text\")"; \
		exit 2; \
	fi; \
	for repo in $(REPO_DIRS); do \
		if [ ! -d "$$repo/.git" ]; then \
			echo "skip $$repo (not a git repo)"; \
			continue; \
		fi; \
		git -C "$$repo" add -A; \
		if git -C "$$repo" diff --cached --quiet; then \
			echo "no staged changes in $$repo; skipping"; \
			continue; \
		fi; \
		git -C "$$repo" commit -m "$$msg"; \
	done

# vim: set ts=4 sw=4 noet:
