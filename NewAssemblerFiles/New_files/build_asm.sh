#!/bin/bash
# usage: ./build_asm.sh path/to/program.asm [--readmemh|--intelhex] [--keep]
#
# Pipeline: course .asm syntax -> standard RISC-V asm -> object -> linked
# flat binary -> meminit.hex, ready to feed the simulator.
#
# Intermediates (.s/.o/.elf/.bin) go in a single reusable .build/ scratch
# directory that's overwritten each run, not a new build_<name>/ folder per
# program -- so repeated runs don't accumulate files. Pass --keep to preserve
# them (renamed by program name) for debugging a specific build.
set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

if [ -z "$1" ]; then
    echo "usage: $0 <program.asm> [--readmemh|--intelhex] [--keep]"
    exit 1
fi

ASM_FILE="$1"
shift
MODE="--readmemh"
KEEP=0
for arg in "$@"; do
    case "$arg" in
        --readmemh) MODE="--readmemh" ;;
        --intelhex) MODE="--intelhex" ;;
        --keep) KEEP=1 ;;
    esac
done

BASENAME=$(basename "$ASM_FILE" .asm)
BUILD_DIR=".build"
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

python3 "$SCRIPT_DIR/preprocess.py" "$ASM_FILE" "$BUILD_DIR/$BASENAME.s"
riscv64-unknown-elf-as -march=rv32ima -mabi=ilp32 -o "$BUILD_DIR/$BASENAME.o" "$BUILD_DIR/$BASENAME.s"
riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0x0 -o "$BUILD_DIR/$BASENAME.elf" "$BUILD_DIR/$BASENAME.o"
riscv64-unknown-elf-objcopy -O binary "$BUILD_DIR/$BASENAME.elf" "$BUILD_DIR/$BASENAME.bin"

if [ "$MODE" == "--readmemh" ]; then
    python3 "$SCRIPT_DIR/bin_to_hex.py" "$BUILD_DIR/$BASENAME.bin" meminit.hex --readmemh
else
    python3 "$SCRIPT_DIR/bin_to_hex.py" "$BUILD_DIR/$BASENAME.bin" meminit.hex
fi

echo ""
echo "Disassembly (for sanity-checking against your expected program):"
riscv64-unknown-elf-objdump -d -Mnumeric "$BUILD_DIR/$BASENAME.elf"

if [ "$KEEP" == "1" ]; then
    mv "$BUILD_DIR" "build_$BASENAME"
    echo ""
    echo "Intermediates kept at build_$BASENAME/"
else
    rm -rf "$BUILD_DIR"
fi
