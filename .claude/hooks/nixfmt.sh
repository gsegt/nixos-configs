#!/usr/bin/env bash
# PostToolUse hook: format the .nix file Claude just edited. Never fails the tool call.
input=$(cat)
if command -v jq >/dev/null; then
  f=$(jq -r '.tool_input.file_path // empty' <<<"$input")
else
  f=$(sed -n 's/.*"file_path" *: *"\([^"]*\)".*/\1/p' <<<"$input" | head -n1)
fi
case "$f" in
  *.nix) [ -f "$f" ] && nixfmt "$f" ;;
esac
exit 0
