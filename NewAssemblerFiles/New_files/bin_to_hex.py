#!/usr/bin/env python3
"""
Converts a flat binary image (from objcopy -O binary) into the word-indexed
Intel-hex-style format expected by ram.sv's altsyncram init_file, matching the
exact format your dump_memory tasks already emit (see memory_control_tb.sv /
system_tb.sv):

    :04<addr16><00><word32><checksum8>

where <addr16> is the WORD index (not byte address), and checksum is the
standard two's-complement-of-byte-sum Intel hex checksum, computed over
[record_len, addr_hi, addr_lo, record_type, data_bytes...] -- i.e. reproduced
exactly from the dump_memory task's own algorithm.

RAM is fixed at 16384 words (64KB) per ram.sv's altsyncram (numwords_a=16384,
widthad_a=14). Words beyond the input binary's length are zero-filled; words
containing all zero bytes are skipped entirely (matching dump_memory's
`if (cif0.iload === 0) continue;` behavior, so a fresh/blank ram region round-
trips identically whether it came from simulation readback or this converter).
"""
import struct
import sys

NUM_WORDS = 16384  # 64KB / 4 bytes, matches ram.sv altsyncram sizing

def checksum(byte_list) -> int:
    total = sum(byte_list)
    return (0x100 - total) & 0xFF

def write_intelhex(data: bytes, hex_path: str):
    lines = []
    for i in range(len(data) // 4):
        word = struct.unpack_from('<I', data, i * 4)[0]
        if word == 0:
            continue  # matches dump_memory's skip-if-zero behavior
        addr_hi = (i >> 8) & 0xFF
        addr_lo = i & 0xFF
        rec_bytes = [0x04, addr_hi, addr_lo, 0x00,
                     (word >> 24) & 0xFF, (word >> 16) & 0xFF,
                     (word >> 8) & 0xFF, word & 0xFF]
        chk = checksum(rec_bytes)
        lines.append(f":04{i:04X}00{word:08X}{chk:02X}")
    lines.append(":00000001FF")
    with open(hex_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print(f"wrote {hex_path} (Intel-hex, word-indexed): "
          f"{len(lines)-1} non-zero words out of {len(data)//4} total")

def write_readmemh(data: bytes, hex_path: str):
    # dense: one 32-bit hex value per line, sequential from word 0, padded
    # with zero-words out to NUM_WORDS -- for `$readmemh("meminit.hex", mem);`
    # against a behavioral `logic [31:0] mem [0:NUM_WORDS-1]` array.
    lines = []
    for i in range(NUM_WORDS):
        if i * 4 < len(data):
            word = struct.unpack_from('<I', data, i * 4)[0]
        else:
            word = 0
        lines.append(f"{word:08x}")
    with open(hex_path, 'w') as f:
        f.write('\n'.join(lines) + '\n')
    print(f"wrote {hex_path} ($readmemh, dense): {NUM_WORDS} words")

def main():
    if len(sys.argv) not in (3, 4):
        print(f"usage: {sys.argv[0]} <input.bin> <output.hex> [--readmemh]", file=sys.stderr)
        sys.exit(1)
    bin_path, hex_path = sys.argv[1], sys.argv[2]
    mode = sys.argv[3] if len(sys.argv) == 4 else None

    with open(bin_path, 'rb') as f:
        data = f.read()

    if len(data) > NUM_WORDS * 4:
        print(f"error: binary is {len(data)} bytes, exceeds {NUM_WORDS*4}-byte "
              f"({NUM_WORDS}-word) RAM size", file=sys.stderr)
        sys.exit(1)

    data = data + b'\x00' * ((-len(data)) % 4)  # pad to whole words

    if mode == '--readmemh':
        write_readmemh(data, hex_path)
    else:
        write_intelhex(data, hex_path)

if __name__ == '__main__':
    main()
