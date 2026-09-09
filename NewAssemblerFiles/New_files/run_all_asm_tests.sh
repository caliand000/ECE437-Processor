#!/bin/bash
set -uo pipefail
# note: -e deliberately dropped -- this script is meant to survive individual
# test failures and report on all of them, not abort on the first one.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASM_DIR="$ROOT_DIR/asmFiles"
OUT_DIR="$ROOT_DIR/asm_test_outputs"
REPORT_FILE="$ROOT_DIR/asm_test_report_$(date +"%Y_%m_%d_%I_%M_%p").txt"
SIMULATE=0
SINGLE_FILE=""

while (( "$#" )); do
  case "$1" in
    --simulate) SIMULATE=1; shift ;;
    --single) SINGLE_FILE="${2:-}"; shift 2 ;;
    *) shift ;;
  esac
done

echo "Assembly Test Report File $(date +"%Y_%m_%d_%I_%M_%p")" > "$REPORT_FILE"
echo "Root dir: $ROOT_DIR" >> "$REPORT_FILE"

shopt -s nullglob
default_files=("$ASM_DIR"/*.asm)

if [[ -n "$SINGLE_FILE" ]]; then
  if [[ ! -f "$SINGLE_FILE" ]]; then
    echo "error: --single file not found: $SINGLE_FILE"
    exit 1
  fi
  asm_files=("$SINGLE_FILE")
else
  asm_files=("${default_files[@]}")
fi

count=${#asm_files[@]}
if (( count == 0 )); then
  echo "No .asm files found in $ASM_DIR"
  exit 1
fi

echo "Executing $count assembly test files" | tee -a "$REPORT_FILE"

pass_count=0
fail_count=0
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

# Only creates asm_test_outputs/<name>/ and keeps logs around when a file
# actually fails -- passing files leave nothing behind but the report line.
save_failure_log() {
  local name="$1" logfile="$2" reason="$3"
  mkdir -p "$OUT_DIR/$name"
  cp "$logfile" "$OUT_DIR/$name/"
  echo "$reason: $asm_file" | tee -a "$REPORT_FILE"
  echo "See $OUT_DIR/$name/$(basename "$logfile")" | tee -a "$REPORT_FILE"
}

for i in "${!asm_files[@]}"; do
  asm_file="${asm_files[$i]}"
  name="$(basename "$asm_file" .asm)"
  idx=$((i + 1))

  printf 'processing file %s (%d of %d)\n' "${asm_file#$ROOT_DIR/}" "$idx" "$count" | tee -a "$REPORT_FILE"

  build_log="$scratch/${name}_build.log"
  if ! (cd "$ROOT_DIR" && bash ./NewAssemblerFiles/New_files/build_asm.sh "$asm_file" > "$build_log" 2>&1); then
    save_failure_log "$name" "$build_log" "BUILD FAILED"
    fail_count=$((fail_count + 1))
    continue
  fi
  echo "ASSEMBLY OK: $asm_file" | tee -a "$REPORT_FILE"

  if (( SIMULATE )); then
    # NOTE: source/ram.sv still instantiates the Altera `altsyncram`
    # primitive as of this writing, which Icarus cannot elaborate. This path
    # will fail here until ram.sv is swapped for a behavioral RAM model --
    # not a bug in this script.
    compile_log="$scratch/${name}_compile.log"
    if ! (cd "$ROOT_DIR" && iverilog -g2012 -I./include -s system_tb -o "$scratch/${name}.out" testbench/system_tb.sv source/*.sv > "$compile_log" 2>&1); then
      save_failure_log "$name" "$compile_log" "SIM COMPILE FAILED"
      fail_count=$((fail_count + 1))
      continue
    fi

    run_log="$scratch/${name}_run.log"
    if ! (cd "$ROOT_DIR" && vvp "$scratch/${name}.out" > "$run_log" 2>&1); then
      save_failure_log "$name" "$run_log" "SIM RUN FAILED"
      fail_count=$((fail_count + 1))
      continue
    fi

    # A clean exit only means the process didn't crash -- it does NOT mean
    # the CPU actually halted. Require the halt line explicitly.
    halt_line="$(grep -o "Halted at.*ran for[[:space:]]*[0-9]*[[:space:]]*cycles\." "$run_log" || true)"
    if [[ -z "$halt_line" ]]; then
      save_failure_log "$name" "$run_log" "SIM RUN FAILED (no halt detected)"
      fail_count=$((fail_count + 1))
      continue
    fi
    cycles="$(echo "$halt_line" | grep -o '[0-9]\+' | tail -1)"
    echo "SIM OK: $asm_file - $cycles cycles" | tee -a "$REPORT_FILE"
  fi

  pass_count=$((pass_count + 1))
done

echo "" | tee -a "$REPORT_FILE"
echo "Completed $count assembly tests: $pass_count passed, $fail_count failed" | tee -a "$REPORT_FILE"
if (( fail_count > 0 )); then
  echo "Failure logs in $OUT_DIR" | tee -a "$REPORT_FILE"
fi

(( fail_count == 0 ))
