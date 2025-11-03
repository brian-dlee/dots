if [[ "$OSTYPE" == darwin-* ]]; then
  alias cbcp="pbcopy"
  alias cbps="pbpaste"
fi

if [[ "$OSTYPE" == linux-* ]]; then
  if command -v wl-copy 2>&1 >/dev/null; then
    alias pbcopy="wl-copy"
    alias cbcp="wl-copy"
  fi

  if command -v wl-paste 2>&1 >/dev/null; then
    alias pbpaste="wl-paste"
    alias cbps="wl-paste"
  fi
fi
