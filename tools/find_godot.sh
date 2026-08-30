#!/usr/bin/env bash

find_godot() {
  if [[ -n "${GODOT_BIN:-}" ]]; then
    printf '%s\n' "$GODOT_BIN"
  elif [[ -x "/Applications/Godot.app/Contents/MacOS/Godot" ]]; then
    printf '%s\n' "/Applications/Godot.app/Contents/MacOS/Godot"
  elif command -v godot4 >/dev/null 2>&1; then
    command -v godot4
  elif command -v godot >/dev/null 2>&1; then
    command -v godot
  else
    return 1
  fi
}
