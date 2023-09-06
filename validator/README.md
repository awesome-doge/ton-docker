# TON Docker

下載
```
git clone https://github.com/awesome-doge/ton-docker.git
```

編譯
```
cd ton-docker
docker build \
  -t ton-docker:latest . \
  --no-cache
```

創建 volume
```
docker volume create ton-work-db
```

啟動 
```
docker run --name ton-node \
  --mount source=ton-work-db,target=/var/ton-work/db \
  --network host \
  -e "PUBLIC_IP=<YOUR_PUBLIC_IP>" \
  -e "CONSOLE_PORT=<TCP-PORT1>" \
  -e "LITESERVER=true" \
  -e "LITE_PORT=<TCP-PORT2>" \
  -e "VALIDATOR_VERBOSITY=<1 or 2 or 3 or 4>"
  -it ton-docker:latest
```
```
docker run --name ton-node \
  --mount source=ton-work-db,target=/var/ton-work/db \
  --network host \
  -e "PUBLIC_IP=125.228.116.218" \
  -e "CONSOLE_PORT=9527" \
  -e "LITESERVER=true" \
  -e "LITE_PORT=9528" \
  -e "VALIDATOR_VERBOSITY=3" \
  -e "VALIDATOR_THREADS=3" \
  -e "VALIDATOR_STATE_TTL=315360000" \
  -e "VALIDATOR_ARCHIVE_TTL=315360000" \
  -e "VALIDATOR_BLOCK_TTL=315360000" \
  -it ton-docker:latest
```

## 取出 liteserver.pub
```
docker cp <container-id>:/var/ton-work/db/liteserver.pub /your/path
```
```
docker cp ton-node:/var/ton-work/db/liteserver.pub .
```

## 交互
validator-engine-console
```
/usr/bin/ton/validator-engine-console/validator-engine-console \
  -k /var/ton-work/db/client \
  -p /var/ton-work/db/server.pub \
  -a <IP>:<TCP-PORT2>
```
```
/usr/bin/ton/validator-engine-console/validator-engine-console \
  -k /var/ton-work/db/client \
  -p /var/ton-work/db/server.pub \
  -a localhost:9527
```
```
docker exec \
  -ti ton-node \
  /usr/bin/ton/validator-engine-console/validator-engine-console \
  -k /var/ton-work/db/client \
  -p /var/ton-work/db/server.pub \
  -a localhost:9527
```

lite-client
```
/usr/bin/ton/lite-client/lite-client \
  -p /var/ton-work/db/liteserver.pub \
  -a <IP>:<TCP-PORT2> 
```
```
/usr/bin/ton/lite-client/lite-client \
  -p /var/ton-work/db/liteserver.pub \
  -a localhost:9528
```
```
docker exec \
  -ti ton-node \
  /usr/bin/ton/lite-client/lite-client \
  -p /var/ton-work/db/liteserver.pub \
  -a localhost:9528 \
  --cmd "help"
```

docker exec \
  -ti ton-node \
  /usr/bin/ton/lite-client/lite-client \
  -C /usr/bin/ton/global.config.json \
  -a localhost:9528 \
  --cmd "getconfig 1"

```
docker exec \
  -ti ton-node \
  /usr/bin/ton/lite-client/lite-client \
  -C /usr/bin/ton/global.config.json \
  -a localhost:9528 \
  --cmd "getconfig 0" \
  --cmd "getconfig 1" \
  --cmd "getconfig 2" \
  --cmd "getconfig 3" \
  --cmd "getconfig 4" \
  --cmd "getconfig 5" \
  --cmd "getconfig 6" \
  --cmd "getconfig 7" \
  --cmd "getconfig 8" \
  --cmd "getconfig 9" \
  --cmd "getconfig 10" \
  --cmd "getconfig 11" \
  --cmd "getconfig 12" \
  --cmd "getconfig 13" \
  --cmd "getconfig 14" \
  --cmd "getconfig 15" \
  --cmd "getconfig 16" \
  --cmd "getconfig 17" \
  --cmd "getconfig 18" \
  --cmd "getconfig 19" \
  --cmd "getconfig 20" \
  --cmd "getconfig 21" \
  --cmd "getconfig 22" \
  --cmd "getconfig 23" \
  --cmd "getconfig 24" \
  --cmd "getconfig 25" \
  --cmd "getconfig 26" \
  --cmd "getconfig 27" \
  --cmd "getconfig 28" \
  --cmd "getconfig 29" \
  --cmd "getconfig 30" \
  --cmd "getconfig 31" \
  --cmd "getconfig 32" \
  --cmd "getconfig 33" \
  --cmd "getconfig 34" \
  --cmd "getconfig 35" \
  --cmd "getconfig 36" \
  --cmd "getconfig 37" \
  --cmd "getconfig 38" \
  --cmd "getconfig 39" \
  --cmd "getconfig 40" \
  -v 0
  ```