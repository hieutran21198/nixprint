#!/usr/bin/env bash
set -euo pipefail

test_root=$(git rev-parse --show-toplevel)
test_file="$test_root/services/agent/tests/eval.nix"

nix-instantiate --eval --strict --json "$test_file" >/dev/null

invalid_doctor=$(mktemp)
trap 'rm -f "$invalid_doctor"' EXIT
nix-instantiate --eval --strict --raw --attr doctorInvalidScript "$test_file" >"$invalid_doctor"
if output=$(bash "$invalid_doctor"); then
  exit 1
fi

case "$output" in
  *"[FAIL] workspace.composition.agent requires at least one enabled client"*"RESULT: INVALID"*) ;;
  *) exit 1 ;;
esac
