#!/bin/bash
# Wrapper for git ssh signing that unsets SSH_AUTH_SOCK to prevent
# ssh-keygen from attempting to use a locked ssh-agent (like 1Password).
# This forces the use of the static SSH key file.

env -u SSH_AUTH_SOCK ssh-keygen "$@"
