# TON Docker
```
git clone https://github.com/awesome-doge/ton-docker.git
cd ton-docker/validator
docker-compose up --build
```

## docker-compose
```
services:
  ton-node:
    build:
      context: ./  
      dockerfile: Dockerfile 

    image: ton-docker:latest
    # 容器名稱
    container_name: ton-node
    # validator udp + control tcp + liteserver tcp 要開出去
    ports:
      - "9527:9527"
      - "9528:9528"

    environment:
      - PUBLIC_IP=125.228.116.218
      - VALIDATOR_PORT=9527 # validator & control 端口
      - LITESERVER=true # 是否開啟 Liteserver
      - LITE_PORT=9528 # Liteserver 端口
      - VALIDATOR_VERBOSITY=2 # LOG 能見度
      - VALIDATOR_THREADS=2 # 使用的 執行序數量
      - ARCHIVE_NODE=0 # 是否回 歸檔節點
      - MAINNET=1 # 是否為主網

    # !!!記得掛硬碟 !!! 只要掛上了硬碟 就不可以再切 主網 或 測試網 因為 DB 已經寫死
    volumes:
      - ton-fullnode:/var/ton-work/db

volumes:
  ton-fullnode:
```

## 取出 key
```
docker cp ton-node:/var/ton-work/db/client .
docker cp ton-node:/var/ton-work/db/client.pub .

docker cp ton-node:/var/ton-work/db/server .
docker cp ton-node:/var/ton-work/db/server.pub .

docker cp ton-node:/var/ton-work/db/liteserver .
docker cp ton-node:/var/ton-work/db/liteserver.pub .

docker cp ton-node:/var/ton-work/db/config.json .
```

## 交互
### validator-engine-console
```
docker exec \
  -ti ton-node \
  /usr/bin/ton/validator-engine-console/validator-engine-console \
  -k /var/ton-work/db/client \
  -p /var/ton-work/db/server.pub \
  -a localhost:9527
```

### lite-client
```
docker exec \
  -ti ton-node \
  /usr/bin/ton/lite-client/lite-client \
  -p /var/ton-work/db/liteserver.pub \
  -a localhost:9528 \
  --cmd "getconfig 1"
```

```
docker exec \
  -ti ton-node \
  /usr/bin/ton/lite-client/lite-client \
  -C /usr/bin/ton/global.config.json \
  -a localhost:9528 \
  --cmd "getconfig 1"
```

---

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



