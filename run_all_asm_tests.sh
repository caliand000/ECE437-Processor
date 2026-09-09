#!/bin/bash
set -uo pipefail
# Continue after individual failures so the complete test set is reported.

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASM_DIR="$ROOT_DIR/asmFiles"
OUT_DIR="$ROOT_DIR/asm_test_outputs"
REPORT_FILE="$ROOT_DIR/asm_test_report_$(date +"%Y_%m_%d_%I_%M_%p").txt"
SIMULATE=0
SINGLE_FILE=""

while (( "$#" )); do
  case "$1" in
    --simulate)
      SIMULATE=1
      shift
      ;;
    --single)
      SINGLE_FILE="${2:-}"
      shift 2
      ;;
    *)
      shift
      ;;
  esac
done

mkdir -p "$OUT_DIR"

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

for i in "${!asm_files[@]}"; do
  asm_file="${asm_files[$i]}"
  name="$(basename "$asm_file" .asm)"
  idx=$((i + 1))

  printf 'processing file %s (%d of %d)\n' "${asm_file#$ROOT_DIR/}" "$idx" "$count" | tee -a "$REPORT_FILE"

  out_subdir="$OUT_DIR/$name"
  mkdir -p "$out_subdir"
  cp "$asm_file" "$out_subdir/${name}.asm"

  asm_path="$(cd "$(dirname "$asm_file")" && pwd)/$(basename "$asm_file")"
  if ! (cd "$out_subdir" && bash "$ROOT_DIR/NewAssemblerFiles/New_files/build_asm.sh" "$asm_path" > "$out_subdir/build.log" 2>&1); then
    echo "BUILD FAILED: $asm_file" | tee -a "$REPORT_FILE"
    echo "See $out_subdir/build.log" | tee -a "$REPORT_FILE"
    fail_count=$((fail_count + 1))
    continue
  fi

  cp "$out_subdir/meminit.hex" "$ROOT_DIR/meminit.hex"
  echo "ASSEMBLY OK: $asm_file" | tee -a "$REPORT_FILE"

  if (( SIMULATE )); then
    # This requires an Icarus installation with the project's RAM primitive
    # and SystemVerilog interfaces available.
    if ! (cd "$ROOT_DIR" && iverilog -g2012 -I./include -s system_tb -o "$out_subdir/system_tb.out" testbench/system_tb.sv source/*.sv > "$out_subdir/system_compile.log" 2>&1); then
      echo "SIM COMPILE FAILED: $asm_file" | tee -a "$REPORT_FILE"
      echo "See $out_subdir/system_compile.log" | tee -a "$REPORT_FILE"
      fail_count=$((fail_count + 1))
      continue
    fi

    if ! (cd "$ROOT_DIR" && vvp "$out_subdir/system_tb.out" > "$out_subdir/system_run.log" 2>&1); then
      echo "SIM RUN FAILED: $asm_file" | tee -a "$REPORT_FILE"
      echo "See $out_subdir/system_run.log" | tee -a "$REPORT_FILE"
      fail_count=$((fail_count + 1))
      continue
    fi

    halt_line="$(grep -o "Halted at.*ran for[[:space:]]*[0-9]*[[:space:]]*cycles\." "$out_subdir/system_run.log" || true)"
    if [[ -z "$halt_line" ]]; then
      echo "SIM RUN FAILED: $asm_file (no halt detected)" | tee -a "$REPORT_FILE"
      echo "See $out_subdir/system_run.log" | tee -a "$REPORT_FILE"
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
echo "Outputs stored in $OUT_DIR" | tee -a "$REPORT_FILE"

(( fail_count == 0 ))
