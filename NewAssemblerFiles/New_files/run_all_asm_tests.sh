#!/bin/bash
set -uo pipefail

# Delegate directly to top-level runner
ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
exec bash "$ROOT_DIR/run_all_asm_tests.sh" "$@"
