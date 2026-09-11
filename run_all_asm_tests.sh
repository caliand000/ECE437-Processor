#!/bin/bash
set -uo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASM_DIR="$ROOT_DIR/asmFiles"
OUT_DIR="$ROOT_DIR/asm_test_outputs"
REPORT_FILE="$ROOT_DIR/asm_test_report_$(date +"%Y_%m_%d_%I_%M_%p").txt"
SIMULATE=0
SINGLE_FILE=""

# ANSI Colors for clean terminal display
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

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

echo "==================================================" > "$REPORT_FILE"
echo "Assembly Test Report - $(date +"%Y-%m-%d %I:%M:%S %p")" >> "$REPORT_FILE"
echo "Root Directory: $ROOT_DIR" >> "$REPORT_FILE"
echo "Simulate Mode: $SIMULATE" >> "$REPORT_FILE"
echo "==================================================" >> "$REPORT_FILE"

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

echo "Executing $count assembly test files..."
echo "" >> "$REPORT_FILE"

if (( SIMULATE )); then
  if [[ ! -x "$ROOT_DIR/obj_dir/Vsystem_tb" ]]; then
    echo "Compiling system testbench with Verilator..."
    if ! (cd "$ROOT_DIR" && verilator --binary --timing --Wno-fatal -Iinclude --top-module system_tb testbench/system_tb.sv source/*.sv > "$OUT_DIR/verilator_compile.log" 2>&1); then
      echo -e "${RED}FAIL${NC}: Verilator testbench compilation failed (see $OUT_DIR/verilator_compile.log)"
      echo "VERILATOR COMPILE FAILED" >> "$REPORT_FILE"
      exit 1
    fi
  fi
fi

pass_count=0
fail_count=0

for i in "${!asm_files[@]}"; do
  asm_file="${asm_files[$i]}"
  name="$(basename "$asm_file" .asm)"
  rel_path="${asm_file#$ROOT_DIR/}"

  out_subdir="$OUT_DIR/$name"
  mkdir -p "$out_subdir"
  cp "$asm_file" "$out_subdir/${name}.asm"

  asm_path="$(cd "$(dirname "$asm_file")" && pwd)/$(basename "$asm_file")"
  if ! (cd "$out_subdir" && bash "$ROOT_DIR/NewAssemblerFiles/New_files/build_asm.sh" "$asm_path" > "$out_subdir/build.log" 2>&1); then
    echo -e "${RED}FAIL${NC}: $rel_path (Build Failed)"
    echo "[FAIL] $rel_path - Build Failed (See $out_subdir/build.log)" >> "$REPORT_FILE"
    fail_count=$((fail_count + 1))
    continue
  fi

  cp "$out_subdir/meminit.hex" "$ROOT_DIR/meminit.hex"

  if (( SIMULATE )); then
    if ! (cd "$ROOT_DIR" && ./obj_dir/Vsystem_tb > "$out_subdir/system_run.log" 2>&1); then
      echo -e "${RED}FAIL${NC}: $rel_path (Simulation Run Failed)"
      echo "[FAIL] $rel_path - Simulation Run Failed (See $out_subdir/system_run.log)" >> "$REPORT_FILE"
      fail_count=$((fail_count + 1))
      continue
    fi

    halt_line="$(grep -o "Halted at.*ran for[[:space:]]*[0-9]*[[:space:]]*cycles\." "$out_subdir/system_run.log" || true)"
    if [[ -z "$halt_line" ]]; then
      echo -e "${RED}FAIL${NC}: $rel_path (No Halt Detected)"
      echo "[FAIL] $rel_path - No Halt Detected (See $out_subdir/system_run.log)" >> "$REPORT_FILE"
      fail_count=$((fail_count + 1))
      continue
    fi

    cycles="$(echo "$halt_line" | grep -o '[0-9]\+' | tail -1)"
    echo -e "${GREEN}PASS${NC}: $rel_path ($cycles cycles)"
    echo "[PASS] $rel_path - Assembly OK | Simulation OK ($cycles cycles)" >> "$REPORT_FILE"
  else
    echo -e "${GREEN}PASS${NC}: $rel_path"
    echo "[PASS] $rel_path - Assembly OK" >> "$REPORT_FILE"
  fi

  pass_count=$((pass_count + 1))
done

echo ""
echo "==================================================" >> "$REPORT_FILE"
echo "Summary: $count total | $pass_count passed | $fail_count failed" >> "$REPORT_FILE"
echo "Outputs stored in $OUT_DIR" >> "$REPORT_FILE"

if (( fail_count == 0 )); then
  echo -e "${GREEN}Completed $count assembly tests: $pass_count passed, $fail_count failed${NC}"
else
  echo -e "${RED}Completed $count assembly tests: $pass_count passed, $fail_count failed${NC}"
fi
echo "Report log: ${REPORT_FILE#$ROOT_DIR/}"

(( fail_count == 0 ))
