# Stage 1: Build environment
FROM ubuntu:22.04 as builder

# Install essential build tools and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl git \
    gcc-arm-linux-gnueabihf \
    gcc-aarch64-linux-gnu \
    gcc-mips-linux-gnu gcc-s390x-linux-gnu \
    libc6-armhf-cross libc6-dev-armhf-cross \
    libc6-arm64-cross libc6-dev-arm64-cross \
    libc6-mips-cross libc6-dev-mips-cross \
    libc6-s390x-cross libc6-dev-s390x-cross \
    cargo \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Rust
RUN curl https://sh.rustup.rs -sSf | bash -s -- -y \
    && export PATH=$PATH:/root/.cargo/bin \
    && rustup target add armv7-unknown-linux-gnueabihf \
    && rustup target add aarch64-unknown-linux-gnu \
    && rustup target add powerpc64le-unknown-linux-gnu \
    && rustup target add i686-unknown-linux-gnu \
    && rustup target add s390x-unknown-linux-gnu

# Clone geckodriver and set up build environment
RUN git clone https://github.com/mozilla/geckodriver.git /opt/geckodriver \
    && cd /opt/geckodriver \
    && git checkout v0.35.0

# Copy the build script to the container
COPY build-arm.sh /opt/geckodriver/

# Build geckodriver for multiple architectures
WORKDIR /opt/geckodriver
RUN sh build-arm.sh release armv7-unknown-linux-gnueabihf \
    && sh build-arm.sh release aarch64-unknown-linux-gnu \
    && sh build-arm.sh release powerpc64le-unknown-linux-gnu \
    && sh build-arm.sh release i686-unknown-linux-gnu \
    && sh build-arm.sh release s390x-unknown-linux-gnu

# Stage 2: Final image
FROM debian:latest

# Copy the built binaries from the builder stage
COPY --from=builder /opt/geckodriver/target/armv7-unknown-linux-gnueabihf/release/geckodriver /usr/local/bin/geckodriver-armv7
COPY --from=builder /opt/geckodriver/target/aarch64-unknown-linux-gnu/release/geckodriver /usr/local/bin/geckodriver-aarch64
COPY --from=builder /opt/geckodriver/target/powerpc64le-unknown-linux-gnu/release/geckodriver /usr/local/bin/geckodriver-powerpc64le
COPY --from=builder /opt/geckodriver/target/i686-unknown-linux-gnu/release/geckodriver /usr/local/bin/geckodriver-i686
COPY --from=builder /opt/geckodriver/target/s390x-unknown-linux-gnu/release/geckodriver /usr/local/bin/geckodriver-s390x

# Ensure that the binaries are executable
RUN chmod +x /usr/local/bin/geckodriver-armv7 \
    /usr/local/bin/geckodriver-aarch64 \
    /usr/local/bin/geckodriver-powerpc64le \
    /usr/local/bin/geckodriver-i686 \
    /usr/local/bin/geckodriver-s390x

# Set the default command
CMD ["geckodriver-armv7"]
