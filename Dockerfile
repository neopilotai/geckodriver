# Base image
FROM debian:latest AS builder

LABEL name="geckodriver"
LABEL version="1.0"
LABEL description="Builds latest ARM binaries of linux geckodriver"
LABEL maintainer="Mozilla, enhancements by neopilotai"
LABEL source="https://github.com/mozilla/geckodriver"

# Set noninteractive frontend
# Dockerfile — set DEBIAN_FRONTEND as an environment variable
ENV DEBIAN_FRONTEND=noninteractive
ARG GECKODRIVER_VERSION

ENV CARGO_HOME=/root/.cargo
ENV PATH="$CARGO_HOME/bin:$PATH"

# Install dependencies
WORKDIR /opt

RUN apt-get update -qqy && \
    apt-get install -y --no-install-recommends \
      gcc build-essential git ca-certificates curl \
      gcc-arm-linux-gnueabihf libc6-armhf-cross libc6-dev-armhf-cross \
      gcc-aarch64-linux-gnu libc6-arm64-cross libc6-dev-arm64-cross && \
    curl https://sh.rustup.rs -sSf | bash -s -- -y && \
    git clone https://github.com/mozilla/geckodriver.git && \
    cd geckodriver && \
    git checkout v${GECKODRIVER_VERSION:-latest} && \
    $CARGO_HOME/bin/rustup target install armv7-unknown-linux-gnueabihf && \
    $CARGO_HOME/bin/rustup target install aarch64-unknown-linux-gnu && \
    mkdir -p .cargo && \
    echo '[target.armv7-unknown-linux-gnueabihf]'      >> .cargo/config && \
    echo 'linker = "arm-linux-gnueabihf-gcc"'          >> .cargo/config && \
    echo '[target.aarch64-unknown-linux-gnu]'          >> .cargo/config && \
    echo 'linker = "aarch64-linux-gnu-gcc"'            >> .cargo/config && \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Copy build script into repo
COPY build-arm.sh /opt/geckodriver/

WORKDIR /opt/geckodriver

# Expose artifacts
ENV ARTIFACTS_DIR=/opt/artifacts
RUN mkdir -p $ARTIFACTS_DIR

# Build geckodriver arm binary and copy to artifacts
CMD ["bash", "build-arm.sh", "release", "aarch64-unknown-linux-gnu", "/opt/artifacts"]

# HEALTHCHECK example (optional)
HEALTHCHECK --interval=10s --timeout=5s CMD [ -f /opt/artifacts/geckodriver ] || exit 1
