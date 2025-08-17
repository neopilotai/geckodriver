#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

show_help() {
    echo -e "${YELLOW}Usage: $0 [release|debug] [TARGET_TRIPLE] [DEST_DIR]${NC}"
    echo "  release|debug   Build type (default: release)"
    echo "  TARGET_TRIPLE   Rust target triple (e.g., aarch64-unknown-linux-gnu)"
    echo "  DEST_DIR        Output directory (default: /media/host)"
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

TYPE=${1:-release}
HOST_TRIPLE=$2
DEST_DIR=${3:-/media/host}

if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

if ! command -v cargo > /dev/null; then
    log_error "Cargo is not installed. Please install Rust and Cargo."
    exit 1
fi

if ! command -v rustup > /dev/null; then
    log_error "Rustup is not installed. Please install Rustup."
    exit 1
fi

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
else
    log_warn "$HOME/.cargo/env not found, continuing..."
fi

TARGET=""
if [ -n "$HOST_TRIPLE" ]; then
    TARGET="--target $HOST_TRIPLE"
    if ! rustup target list | grep -q "$HOST_TRIPLE (installed)"; then
        log_info "Adding Rust target: $HOST_TRIPLE"
        rustup target add "$HOST_TRIPLE"
    fi
fi

JOBS=${JOBS:-$(nproc 2>/dev/null || echo 1)}
log_info "Building geckodriver with type: $TYPE, target: ${HOST_TRIPLE:-host}, jobs: $JOBS"
BUILD_ARGS=(build)
[ -n "$HOST_TRIPLE" ] && BUILD_ARGS+=(--target "$HOST_TRIPLE")
BUILD_ARGS+=(--jobs "$JOBS")
[ "$TYPE" = "release" ] && BUILD_ARGS+=(--release)

cargo "${BUILD_ARGS[@]}"
TARGET_DIR="target"
if [ -z "$HOST_TRIPLE" ]; then
    TARGET_FILE="$TARGET_DIR/$TYPE/geckodriver"
else
    TARGET_FILE="$TARGET_DIR/$HOST_TRIPLE/$TYPE/geckodriver"
fi

if [ -f "$TARGET_FILE" ]; then
    log_info "Copying $TARGET_FILE to $DEST_DIR"
    mkdir -p "$DEST_DIR"
    cp "$TARGET_FILE" "$DEST_DIR"
    log_info "Build and copy successful!"
else
    log_error "$TARGET_FILE not found!"
    exit 1
fi
