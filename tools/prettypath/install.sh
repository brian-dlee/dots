#!/usr/bin/env bash

set -e

PREFIX=${PREFIX:-"$HOME/.local"}

echo "PREFIX is '$PREFIX'" >&2

if [[ ! -e "$PREFIX/bin" ]]; then
  echo "Creating $PREFIX/bin" >&2
  mkdir -p "$PREFIX/bin"
fi

project_dir=$(dirname "$(realpath "$0")")

echo "Compiling $project_dir/main.go to $PREFIX/bin/prettypath"

go build -o "$PREFIX/bin/prettypath" "$project_dir/main.go"
