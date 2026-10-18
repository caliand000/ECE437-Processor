#!/usr/bin/env bash
# Build and install Spike (RISC-V ISA simulator) into $HOME/riscv.
# Target: WSL2 Ubuntu 24.04 and GitHub Actions ubuntu-24.04. Takes a few minutes.
#
# Env overrides:
#   RISCV      install prefix (default $HOME/riscv)
#   SPIKE_REF  git tag/commit to build (default: repo default branch).
#              Pin this once you have confirmed a version works locally.
#   SKIP_APT=1 skip apt installs (CI installs deps in a separate, always-run step)
set -euo pipefail

PREFIX="${RISCV:-$HOME/riscv}"

if [ "${SKIP_APT:-0}" != "1" ]; then
  sudo apt-get update
  sudo apt-get install -y build-essential git device-tree-compiler \
    libboost-regex-dev libboost-system-dev python3
fi

mkdir -p "$HOME/src"
cd "$HOME/src"
[ -d riscv-isa-sim ] || git clone https://github.com/riscv-software-src/riscv-isa-sim.git
cd riscv-isa-sim
if [ -n "${SPIKE_REF:-}" ]; then
  git fetch --tags origin
  git checkout "$SPIKE_REF"
fi
echo "Building Spike at $(git rev-parse HEAD)"

mkdir -p build
cd build
../configure --prefix="$PREFIX"
make -j"$(nproc)"
make install

# put spike on PATH for future interactive shells
if ! grep -q "$PREFIX/bin" "$HOME/.bashrc" 2>/dev/null; then
  echo "export PATH=\"$PREFIX/bin:\$PATH\"" >> "$HOME/.bashrc"
fi
export PATH="$PREFIX/bin:$PATH"

echo "Installed: $(command -v spike)"
spike --help 2>&1 | head -n 5 || true
