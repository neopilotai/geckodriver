# Base image
FROM debian:latest

# Labels and Credits
LABEL \
  name="geckodriver" \
  authors="Mozilla" \
  contribution="latest ARM binaries of linux geckodriver"

# tags local/geckodriver

ARG GECKODRIVER_VERSION

# Install dependencies and clone geckodriver source
WORKDIR /opt

# Separate RUN commands to debug step by step
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc build-essential git cargo ca-certificates curl

RUN apt-get install -y --no-install-recommends \
    gcc-arm-linux-gnueabihf libc6-armhf-cross libc6-dev-armhf-cross

RUN apt-get install -y --no-install-recommends \
    gcc-aarch64-linux-gnu libc6-arm64-cross libc6-dev-arm64-cross

RUN apt-get install -y --no-install-recommends \
    gcc-powerpc64le-linux-gnu libc6-ppc64le-cross libc6-dev-ppc64le-cross

RUN apt-get install -y --no-install-recommends \
    gcc-multilib gcc-multilib-arm-linux-gnueabihf

RUN apt-get install -y --no-install-recommends \
    gcc-s390x-linux-gnu libc6-s390x-cross libc6-dev-s390x-cross

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y

# Clone and checkout geckodriver
RUN git clone https://github.com/mozilla/geckodriver.git && \
    cd geckodriver && \
    git checkout v$GECKODRIVER_VERSION && \
    /root/.cargo/bin/rustup target install armv7-unknown-linux-gnueabihf && \
    /root/.cargo/bin/rustup target install aarch64-unknown-linux-gnu && \
    /root/.cargo/bin/rustup target install powerpc64le-unknown-linux-gnu && \
    /root/.cargo/bin/rustup target install i686-unknown-linux-gnu && \
    /root/.cargo/bin/rustup target install s390x-unknown-linux-gnu && \
    echo "[target.armv7-unknown-linux-gnueabihf]" >> .cargo/config && \
    echo "linker = \"arm-linux-gnueabihf-gcc\"" >> .cargo/config && \
    echo "[target.aarch64-unknown-linux-gnu]" >> .cargo/config && \
    echo "linker = \"aarch64-linux-gnu-gcc\""  >> .cargo/config && \
    echo "[target.powerpc64le-unknown-linux-gnu]" >> .cargo/config && \
    echo "linker = \"powerpc64le-linux-gnu-gcc\""  >> .cargo/config && \
    echo "[target.i686-unknown-linux-gnu]" >> .cargo/config && \
    echo "linker = \"gcc -m32\""  >> .cargo/config && \
    echo "[target.s390x-unknown-linux-gnu]" >> .cargo/config && \
    echo "linker = \"s390x-linux-gnu-gcc\""  >> .cargo/config

# Cleanup
RUN apt-get autoremove -y && apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/*

# Copy build script to container
COPY build-arm.sh /opt/geckodriver/

# Build geckodriver arm binary and copy to $PWD/artifacts
CMD ["sh", "build-arm.sh"]
