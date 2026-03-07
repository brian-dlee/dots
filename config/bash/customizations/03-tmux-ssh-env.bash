# Sync SSH_CONNECTION from tmux session environment on every prompt.
# This ensures that existing panes reflect the current SSH context
# after reattaching to a tmux session over SSH.

if [ -n "$TMUX" ]; then
	_sync_ssh_env() {
		local val
		val=$(tmux show-environment SSH_CONNECTION 2>/dev/null)
		if [[ "$val" == -SSH_CONNECTION ]]; then
			unset SSH_CONNECTION
		elif [[ "$val" == SSH_CONNECTION=* ]]; then
			export "$val"
		fi
	}
	PROMPT_COMMAND="_sync_ssh_env${PROMPT_COMMAND:+;$PROMPT_COMMAND}"
fi
