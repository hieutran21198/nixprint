#!/usr/bin/env bash
set -euo pipefail

test_root=$(git rev-parse --show-toplevel)
nix-instantiate --eval --strict --json "$test_root/services/agent/tests/eval.nix" >/dev/null
