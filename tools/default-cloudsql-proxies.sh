#!/bin/bash
# default-cloudsql-proxies - Start Cloud SQL proxy connections for DBeaver
#
# Config file: ~/.config/dots/tools/default-cloudsql-proxies/connections.conf
# Format: one connection string per line, comments (#) and blank lines ignored
# Example:
#   # project:region:instance?port=NNNN
#   my-project:us-west4:my-instance?port=9010

set -eu

CONFIG="$HOME/.config/dots/tools/default-cloudsql-proxies/connections.conf"

if [[ ! -f "$CONFIG" ]]; then
	echo "Error: config file not found: $CONFIG" >&2
	echo "" >&2
	echo "Create it with one connection string per line, e.g.:" >&2
	echo "  # project:region:instance?port=NNNN" >&2
	echo "  my-project:us-west4:my-instance?port=9010" >&2
	exit 1
fi

# Read connections, strip comments and blank lines
mapfile -t connections < <(grep -v '^\s*#' "$CONFIG" | grep -v '^\s*$')

if [[ ${#connections[@]} -eq 0 ]]; then
	echo "Error: no connections found in $CONFIG" >&2
	exit 1
fi

echo "Starting Cloud SQL proxy with ${#connections[@]} connection(s)..." >&2
exec cloud-sql-proxy "${connections[@]}"
