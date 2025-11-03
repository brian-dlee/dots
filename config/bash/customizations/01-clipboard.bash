if [[ "$OSTYPE" == linux-* ]]; then
  if command -v xsel 2>&1 >/dev/null; then
    alias pbcopy="xsel --clipboard --input"
    alias pbpaste="xsel --clipboard --output"

    alias xcp="xsel --clipboard --input"
    alias xps="xsel --clipboard --output"
  fi
fi
