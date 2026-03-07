#!/bin/bash
# ssh-context - Manages SSH auth socket, signing identity, and signing tool.
#
# Config file: ~/.config/dots/tools/ssh-context/config
# Format: bash-sourceable key=value pairs
# Required variables:
#   BRIDGE        - path to the agent socket symlink (e.g. ~/.ssh/agent.sock)
#   LOCAL_SOCK    - path to the local agent socket (e.g. ~/.1password/agent.sock)
#   REMOTE_SOCK   - path to the remote forwarded socket (e.g. ~/.ssh/remote.sock)
#   KEY_DESKTOP   - SSH public key fingerprint for local machine
#   KEY_LAPTOP    - SSH public key fingerprint for laptop/remote machine
#   PROG_STANDARD - standard signing program (e.g. ssh-keygen)
#   PROG_RICH     - rich signing program (e.g. /opt/1Password/op-ssh-sign)
#
# Usage:
#   ssh-context -c [local|remote|auto]  # Configure the socket bridge
#   ssh-context -i                      # Init: Output exports for eval

set -eu

CONFIG="$HOME/.config/dots/tools/ssh-context/config"

if [[ ! -f "$CONFIG" ]]; then
	echo "Error: config file not found: $CONFIG" >&2
	echo "" >&2
	echo "Create it as a bash-sourceable file, e.g.:" >&2
	echo "  BRIDGE=\"\$HOME/.ssh/agent.sock\"" >&2
	echo "  LOCAL_SOCK=\"\$HOME/.1password/agent.sock\"" >&2
	echo "  REMOTE_SOCK=\"\$HOME/.ssh/remote.sock\"" >&2
	echo "  KEY_DESKTOP=\"ssh-ed25519 AAAA...\"" >&2
	echo "  KEY_LAPTOP=\"ssh-ed25519 AAAA...\"" >&2
	echo "  PROG_STANDARD=\"ssh-keygen\"" >&2
	echo "  PROG_RICH=\"/opt/1Password/op-ssh-sign\"" >&2
	exit 1
fi

# shellcheck source=/dev/null
source "$CONFIG"

usage() {
	echo "Usage: ssh-context -c [local|remote|auto]  # Configure the socket bridge"
	echo "       ssh-context -i                      # Init: Output exports for eval"
	exit 1
}

configure_bridge() {
	local mode=$1

	if [[ "$mode" == "local" ]]; then
		if [[ "$(readlink "$BRIDGE")" != "$LOCAL_SOCK" ]]; then
			ln -sf "$LOCAL_SOCK" "$BRIDGE"
			echo "Bridge connected to: LOCAL (1Password App)" >&2
		fi

	elif [[ "$mode" == "remote" ]]; then
		if [[ "$(readlink "$BRIDGE")" != "$REMOTE_SOCK" ]]; then
			ln -sf "$REMOTE_SOCK" "$BRIDGE"
			echo "Bridge connected to: REMOTE (SSH Forwarding)" >&2
		fi

	elif [[ "$mode" == "auto" ]]; then
		if [[ -n "${SSH_TTY:-}" ]]; then
			configure_bridge remote
		else
			configure_bridge local
		fi
	else
		echo "Error: unknown mode: $mode" >&2
		usage
	fi
}

output_vars() {
	echo "export SSH_AUTH_SOCK=\"$BRIDGE\""

	local current_target
	current_target=$(readlink "$BRIDGE")

	local use_key use_prog
	if [[ "$current_target" == "$LOCAL_SOCK" ]]; then
		use_key="$KEY_DESKTOP"
		if [[ -f "$PROG_RICH" ]]; then
			use_prog="$PROG_RICH"
		else
			use_prog="$PROG_STANDARD"
		fi
	else
		use_key="$KEY_LAPTOP"
		use_prog="$PROG_STANDARD"
	fi

	echo "export GIT_CONFIG_COUNT=2"
	echo "export GIT_CONFIG_KEY_0=user.signingkey"
	echo "export GIT_CONFIG_VALUE_0=\"$use_key\""
	echo "export GIT_CONFIG_KEY_1=gpg.ssh.program"
	echo "export GIT_CONFIG_VALUE_1=\"$use_prog\""
}

if [[ $# -eq 0 ]]; then
	usage
fi

while getopts "c:i" opt; do
	case $opt in
	c) configure_bridge "$OPTARG" ;;
	i) output_vars ;;
	*) usage ;;
	esac
done
