# SPDX-License-Identifier: Apache-2.0
# Copyright (c) 2026 Sandor Miskey (HA5BMS, sandor@HA5BMS.RADIO)
#
# Multi-repo commit helper.
# This justfile commits the listed repositories with the same message.
# It uses `git -C` so you can run it from anywhere, and it skips repos with
# no staged changes. Add repositories by duplicating the commit lines.
#
# Usage:
#   just commit-all your commit message

commit-all *msg:
	@if [ -z "{{msg}}" ]; then \
		echo "msg is required (example: just commit-all your message)"; \
		exit 2; \
	fi
	git -C bms-core add -A
	git -C bms-core diff --cached --quiet || git -C bms-core commit -m "{{msg}}"
	git -C bms-core log -3
	git -C bms-meta add -A
	git -C bms-meta diff --cached --quiet || git -C bms-meta commit -m "{{msg}}"
	git -C bms-meta log -3

# vim: set ts=4 sw=4 noet:
