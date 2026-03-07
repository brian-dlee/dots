#!/usr/bin/env bash
# Force workspaces to their assigned monitors based on current config
# Usage: force-workspace-monitors [home|office]

LOCATION="${1:-auto}"
CONFIG_DIR="$HOME/.dots/config/hypr/core"
WORKSPACES_FILE="$CONFIG_DIR/workspaces.conf"

if [ "$LOCATION" = "auto" ]; then
    if grep -q "Dell Inc. DELL S3221QS" "$WORKSPACES_FILE" 2>/dev/null; then
        LOCATION="office"
    else
        LOCATION="home"
    fi
fi

if [ "$LOCATION" = "office" ]; then
    echo "Moving workspaces 2,3,4 to Dell S3221QS..."
    for ws in 2 3 4; do
        if hyprctl workspaces | grep -q "workspace ID $ws "; then
            hyprctl dispatch moveworkspacetomonitor "$ws" DP-10
        fi
    done
elif [ "$LOCATION" = "home" ]; then
    echo "Home config - no forced moves needed"
fi

echo "Done."
