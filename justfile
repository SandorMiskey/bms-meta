# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)
#
# Multi-repo commit helper.
# This justfile commits the listed repositories with the same message.
# Run it from the workspace root (or via the root symlink) so the relative
# repo paths resolve correctly. Add repositories by duplicating the lines.
#
# Usage:
#   just commit-all your commit message
#   just status-all

section name:
	@printf "\033[1;44;97m  %s  \033[0m\n" "{{name}}"

c *msg:
	@if [ -z "{{msg}}" ]; then \
		echo "msg is required (example: just commit-all your message)"; \
		exit 2; \
	fi
	@just section "bms-core add/commit"
	git -C bms-core add -A
	git -C bms-core diff --cached --quiet || git -C bms-core commit -m "{{msg}}"
	git -C bms-core log -3 --oneline --graph --decorate
	@just section "bms-meta add/commit"
	git -C bms-meta add -A
	git -C bms-meta diff --cached --quiet || git -C bms-meta commit -m "{{msg}}"
	git -C bms-meta log -3 --oneline --graph --decorate

p:
	@just section "bms-core push"
	git -C bms-core push
	@just section "bms-meta push"
	git -C bms-meta push

s:
	@just section "bms-core status"
	git -C bms-core status -sb
	git -C bms-core log -3 --oneline --graph --decorate
	@just section "bms-meta status"
	git -C bms-meta status -sb
	git -C bms-meta log -3 --oneline --graph --decorate

# vim: set ts=4 sw=4 noet:
