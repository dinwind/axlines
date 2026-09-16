#!/usr/bin/env bash
# Start a new task branch from latest remote/trunk (Agent Git/PR lifecycle step 1).
# Prefer: co branch start <branch>
set -euo pipefail
if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <branch>" >&2
	exit 1
fi
co branch start "$1"
