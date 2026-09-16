#!/usr/bin/env bash
# Mandatory post-merge cleanup: return to trunk and delete local + remote head.
# Prefer: co branch cleanup <branch>
set -euo pipefail
if [[ $# -lt 1 ]]; then
	echo "Usage: $0 <branch>" >&2
	exit 1
fi
co branch cleanup "$1"
