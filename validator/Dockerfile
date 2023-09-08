# Builder stage
FROM ubuntu:20.04 as builder

#Update stretch repositories
RUN sed -i s/deb.debian.org/archive.debian.org/g /etc/apt/sources.list
RUN sed -i 's|security.debian.org|archive.debian.org/|g' /etc/apt/sources.list
RUN sed -i '/stretch-updates/d' /etc/apt/sources.list

# Install the necessary packages
RUN apt-get update

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential cmake clang-9 openssl libmicrohttpd-dev pkg-config libssl-dev zlib1g-dev gperf wget git ninja-build
RUN rm -rf /var/lib/apt/lists/*

# /usr/src
WORKDIR /usr/src
RUN git clone --recursive https://github.com/ton-blockchain/ton

# /usr/bin
WORKDIR /usr/bin
RUN mkdir -p /usr/bin/ton

# # Set environment variables
# ENV CC clang-9
# ENV CXX clang++-9
# ENV CCACHE_DISABLE 1

# /usr/bin/ton
WORKDIR /usr/bin/ton
RUN cmake -GNinja -DCMAKE_BUILD_TYPE=Release /usr/src/ton
# 只編譯必要
RUN ninja tonlibjson fift func validator-engine validator-engine-console generate-random-id dht-server lite-client
# 編譯全部
# RUN ninja
# RUN ninja storage-daemon storage-daemon-cli tonlibjson fift func validator-engine validator-engine-console generate-random-id dht-server lite-client

# Final stage
FROM ubuntu:20.04

# Install required runtime packages
RUN apt-get update
RUN apt-get install -y openssl wget libatomic1 jq
RUN rm -rf /var/lib/apt/lists/*

# Copy built binaries from builder stage
COPY --from=builder /usr/src/ton /usr/src/ton
COPY --from=builder /usr/bin/ton /usr/bin/ton

# Create necessary directories
RUN mkdir -p /var/ton-work/db
RUN mkdir -p /var/ton-work/db/import
RUN mkdir -p /var/ton-work/db/static

# Invalidate cache by adding a date-time argument 添加隨機變數 讓 docker cache 失效
ADD "https://www.random.org/cgi-bin/randbyte?nbytes=10&format=h" skipcache

# Setup entrypoint 初始化數據庫路徑
WORKDIR /var/ton-work/db
COPY init.sh control.template ./ 
RUN chmod +x init.sh

ENTRYPOINT ["/var/ton-work/db/init.sh"]