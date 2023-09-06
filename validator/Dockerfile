# Builder stage
FROM ubuntu:20.04 as builder

# Install the necessary packages
RUN apt-get update
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake clang-6.0 openssl libmicrohttpd-dev pkg-config libssl-dev zlib1g-dev gperf wget git ninja-build
RUN rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV CC clang-6.0
ENV CXX clang++-6.0
ENV CCACHE_DISABLE 1

# /usr/src
WORKDIR /usr/src
RUN git clone --recursive https://github.com/ton-blockchain/ton

# /usr/bin
WORKDIR /usr/bin
RUN mkdir -p /usr/bin/ton

# /usr/bin/ton
WORKDIR /usr/bin/ton
RUN cmake -GNinja -DCMAKE_BUILD_TYPE=Release /usr/src/ton
RUN ninja tonlibjson fift func validator-engine validator-engine-console generate-random-id dht-server lite-client
# RUN ninja
# RUN ninja storage-daemon storage-daemon-cli tonlibjson fift func validator-engine validator-engine-console generate-random-id dht-server lite-client

# Final stage
FROM ubuntu:20.04

# Install required runtime packages
RUN apt-get update
RUN apt-get install -y openssl wget libatomic1
RUN rm -rf /var/lib/apt/lists/*

# Copy built binaries from builder stage
COPY --from=builder /usr/src/ton /usr/src/ton
COPY --from=builder /usr/bin/ton /usr/bin/ton

# Create necessary directories
RUN mkdir -p /var/ton-work/db
RUN mkdir -p /var/ton-work/db/static

# Setup entrypoint
WORKDIR /var/ton-work/db
COPY init.sh control.template ./
RUN chmod +x init.sh

ENTRYPOINT ["/var/ton-work/db/init.sh"]