#!/bin/bash
set -e

TYPE=${1:-release}
HOST_TRIPLE=$2

# Ensure the Rust environment is sourced
. $HOME/.cargo/env

# If HOST_TRIPLE is provided, set the target
if [ -n "$HOST_TRIPLE" ]; then
    TARGET="--target $HOST_TRIPLE"

    # Check if the Rust toolchain for the specified target is installed
    if ! rustup target list | grep -q "^$HOST_TRIPLE"; then
        echo "Adding Rust target: $HOST_TRIPLE"
        rustup target add $HOST_TRIPLE
    fi
else
    TARGET=""
fi

# Build the project with the specified type and target
echo "Building geckodriver with type: $TYPE and target: $HOST_TRIPLE"
if [ "$TYPE" = "release" ]; then
    cargo build --release $TARGET
else
    cargo build $TARGET
fi

# Determine the output directory and file based on the target
TARGET_DIR="/opt/geckodriver/target"
if [ -z "$HOST_TRIPLE" ]; then
    TARGET_FILE="$TARGET_DIR/$TYPE/geckodriver"
else
    TARGET_FILE="$TARGET_DIR/$HOST_TRIPLE/$TYPE/geckodriver"
fi

# Copy the built binary to the specified host directory
if [ -f "$TARGET_FILE" ]; then
    echo "Copying $TARGET_FILE to /media/host"
    cp "$TARGET_FILE" /media/host
else
    echo "Error: $TARGET_FILE not found!"
    exit 1
fi
