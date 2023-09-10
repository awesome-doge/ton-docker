#!/usr/bin/env bash

echo -e "v4"

# Color definitions
COLOR_GREEN='\033[92m'
COLOR_RED='\033[91m'
COLOR_YELLOW='\033[93m'
ENDC='\033[0m'

env_variable() {
    # ton environment variable
    export PATH=$PATH:/usr/bin/ton/adnl
    export PATH=$PATH:/usr/bin/ton/blockchain-explorer
    export PATH=$PATH:/usr/bin/ton/create-hardfork
    export PATH=$PATH:/usr/bin/ton/crypto
    export PATH=$PATH:/usr/bin/ton/dht-server
    export PATH=$PATH:/usr/bin/ton/http
    export PATH=$PATH:/usr/bin/ton/lite-client
    export PATH=$PATH:/usr/bin/ton/rldp-http-proxy
    export PATH=$PATH:/usr/bin/ton/storage
    export PATH=$PATH:/usr/bin/ton/tddb
    export PATH=$PATH:/usr/bin/ton/tdfec/benchmark
    export PATH=$PATH:/usr/bin/ton/tdnet
    export PATH=$PATH:/usr/bin/ton/tl/generate
    export PATH=$PATH:/usr/bin/ton/tonlib
    export PATH=$PATH:/usr/bin/ton/utils
    export PATH=$PATH:/usr/bin/ton/validator-engine
    export PATH=$PATH:/usr/bin/ton/validator-engine-console
}

# Display information about the TON node
display_node_info() {
    # echo -e "------------------------------------------------------------"
    echo -e "IP                    ${COLOR_GREEN}$PUBLIC_IP:$VALIDATOR_PORT${ENDC}"
    echo -e "NETWORK               ${COLOR_GREEN}$NETWORK${ENDC}"
    echo -e "NODE_MODE             ${COLOR_GREEN}$NODE_MODE${ENDC}"
    echo -e "VALIDATOR_STATE_TTL   ${COLOR_GREEN}$VALIDATOR_STATE_TTL${ENDC}"
    echo -e "VALIDATOR_ARCHIVE_TTL ${COLOR_GREEN}$VALIDATOR_ARCHIVE_TTL${ENDC}"
    echo -e "VALIDATOR_BLOCK_TTL   ${COLOR_GREEN}$VALIDATOR_BLOCK_TTL${ENDC}"
    echo -e "------------------------------------------------------------"
    # echo -e "${COLOR_YELLOW}/${ENDC}"
    # ls
    # echo -e "------------------------------------------------------------"
    # echo -e "${COLOR_YELLOW}/var/ton-work/db/${ENDC}"
    # ls /var/ton-work/db/
    # echo -e "------------------------------------------------------------"
    # echo -e "${COLOR_YELLOW}/var/ton-work/db/keyring/${ENDC}"
    # ls /var/ton-work/db/keyring/
    # echo -e "------------------------------------------------------------"
    # echo -e "${COLOR_YELLOW}/var/ton-work/db/config.json${ENDC}"
    # cat config.json
    # echo -e "------------------------------------------------------------"
}

# Function to clean old logs
clean_log() {
    find /var/ton-work/db -name 'LOG.old*' -exec rm {} +
    rm -r /var/ton-work/db/files/packages/temp.archive.*
    rm -r /var/ton-work/log*
}

get_global_config() {
    if [[ "$MAINNET" -eq 0 ]]; then
        NETWORK="TESTNET"
        echo -e "- 網路:${COLOR_GREEN} $NETWORK${ENDC}"
        wget -q https://ton-blockchain.github.io/testnet-global.config.json -O /usr/bin/ton/global.config.json
    elif [[ "$MAINNET" -eq 1 ]]; then
        NETWORK="MAINNET"
        echo -e "- 網路:${COLOR_GREEN} $NETWORK${ENDC}"
        wget -q https://ton-blockchain.github.io/global.config.json -O /usr/bin/ton/global.config.json
    else
        echo -e "${COLOR_RED}Invalid value for MAINNET.${ENDC}"
        exit 1
    fi
}

set_archive_node_mode() {
    if [[ "$ARCHIVE_NODE" -eq 0 ]]; then
        echo -e "- 設置 FULL NODE TTL"
        NODE_MODE="FULL NODE MODE"
        VALIDATOR_STATE_TTL=25200
        VALIDATOR_ARCHIVE_TTL=25200
        VALIDATOR_BLOCK_TTL=25200
    elif [[ "$ARCHIVE_NODE" -eq 1 ]]; then
        echo -e "- 設置 ARCHIVE NODE MODE TTL"
        NODE_MODE="ARCHIVE NODE MODE"
        VALIDATOR_STATE_TTL=315360000
        VALIDATOR_ARCHIVE_TTL=315360000
        VALIDATOR_BLOCK_TTL=315360000
    else
        echo "Invalid value for ARCHIVE_NODE."
        exit 1
    fi
}

generate_config_json(){
    # dht, adnl
    validator-engine -C /usr/bin/ton/global.config.json --db /var/ton-work/db --ip "$PUBLIC_IP:$VALIDATOR_PORT" --verbosity $VALIDATOR_VERBOSITY --threads $VALIDATOR_THREADS --state-ttl $VALIDATOR_STATE_TTL --archive-ttl $VALIDATOR_ARCHIVE_TTL --block-ttl $VALIDATOR_BLOCK_TTL
    
    echo -e "- 寫入 dht adnl key 到 /var/ton-work/db/keyring/"
    echo -e "- 寫入 fullnode adnl key 到 /var/ton-work/db/keyring/"
}

generate_server_key() {
    # server, server.pub  
    read -r SERVER_ID1 SERVER_ID2 <<< $(generate-random-id -m keys -n server)
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}- 生成 一組 SERVER_ID1 SERVER_ID2 失敗${ENDC}"
        exit 1
    else
        echo -e "Server IDs:"
        echo -e "    server    : ${COLOR_GREEN}$SERVER_ID1${ENDC}"
        echo -e "    server.pub: ${COLOR_GREEN}$SERVER_ID2${ENDC}"
    fi

    echo -e "- 寫入 server key 到 /var/ton-work/db/keyring/"
    cp server /var/ton-work/db/keyring/$SERVER_ID1
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}- 寫入 Server certificate 到 /var/ton-work/db/keyring/ 失敗{ENDC}"
        exit 1
    fi
}

# dev
generate_dht_key() {
    # dht, dht.pub  
    read -r DHT_ID1 DHT_ID2 <<< $(generate-random-id -m keys -n dht)
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}- 生成 一組 DHT_ID1 DHT_ID2 失敗${ENDC}"
        exit 1
    else
        echo -e "DHT IDs:"
        echo -e "    dht    : ${COLOR_GREEN}$DHT_ID1${ENDC}"
        echo -e "    dht.pub: ${COLOR_GREEN}$DHT_ID2${ENDC}"
    fi

    echo -e "- 寫入 dht key 到 /var/ton-work/db/keyring/"
    cp dht /var/ton-work/db/keyring/$DHT_ID1
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}- 寫入 dht certificate 到 /var/ton-work/db/keyring/ 失敗{ENDC}"
        exit 1
    fi
}

# dev
generate_fullnode_key() {
    # fullnode, fullnode.pub  
    read -r FULLNODE_ID1 FULLNODE_ID2 <<< $(generate-random-id -m keys -n fullnode)
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}- 生成 一組 FULLNODE_ID1 FULLNODE_ID2 失敗${ENDC}"
        exit 1
    else
        echo -e "FULLNODE IDs:"
        echo -e "    andl    : ${COLOR_GREEN}$FULLNODE_ID1${ENDC}"
        echo -e "    andl.pub: ${COLOR_GREEN}$FULLNODE_ID2${ENDC}"
    fi

    echo -e "- 寫入 fullnode key 到 /var/ton-work/db/keyring/"
    cp fullnode /var/ton-work/db/keyring/$FULLNODE_ID1
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}- 寫入 fullnode key 到 /var/ton-work/db/keyring/ 失敗{ENDC}"
        exit 1
    fi
}

generate_client_key() {
    # client, client.pub
    read -r CLIENT_ID1 CLIENT_ID2 <<< $(generate-random-id -m keys -n client)
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}- 生成 一組 CLIENT_ID1 CLIENT_ID2 失敗${ENDC}"
        exit 1
    else
        echo -e "Client IDs:"
        echo -e "    client    : ${COLOR_GREEN}$CLIENT_ID1${ENDC}"
        echo -e "    client.pub: ${COLOR_GREEN}$CLIENT_ID2${ENDC}"
    fi
    
    # 修改 control.template 文件
    # 替換 VALIDATOR_PORT --> CONSOLE-PORT

    # 生成的結果 control.template --> control.new

    # client.pub server.pub 寫入 config.json
    echo -e "- 寫入 client.pub server.pub 寫入 config.json 到 config.json"

    sed -e "s/CONSOLE-PORT/\"$(printf "%q" $VALIDATOR_PORT)\"/g" -e "s~SERVER-ID~\"$(printf "%q" $SERVER_ID2)\"~g" -e "s~CLIENT-ID~\"$(printf "%q" $CLIENT_ID2)\"~g" control.template > control.new
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error generating control.new from template.${ENDC}"
        exit 1
    fi

    # 替換 control/ control.new
    sed -e "s~\"control\"\ \:\ \[~$(printf "%q" $(cat control.new))~g" config.json > config.json.new
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error generating config.json.new.${ENDC}"
        exit 1
    fi
    # 新的 config.json.new 取代 config.json
    mv config.json.new config.json
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error moving config.json.new to config.json.${ENDC}"
        exit 1
    fi
}

generate_liteserver_key() {
    # liteserver, liteserver.pub
    read -r LITESERVER_ID1 LITESERVER_ID2 <<< $(generate-random-id -m keys -n liteserver)
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error generate-random-id -m keys -n liteserver${ENDC}"
        exit 1
    else
        echo -e "Liteserver IDs:"
        echo -e "    liteserver    : ${COLOR_GREEN}$LITESERVER_ID1${ENDC}"
        echo -e "    liteserver.pub: ${COLOR_GREEN}$LITESERVER_ID2${ENDC}"
    fi

    echo -e "- 寫入 liteserver key 到 /var/ton-work/db/keyring/"
    cp liteserver /var/ton-work/db/keyring/$LITESERVER_ID1

    # 替換 LITESERVER_ID2 --> liteservers
    # liteserver.pub  key 寫入 config.json
    LITESERVERS=$(printf "%q" "\"liteservers\":[{\"id\":\"$LITESERVER_ID2\",\"port\":\"$LITE_PORT\"}")
    sed -e "s~\"liteservers\"\ \:\ \[~$LITESERVERS~g" config.json > config.json.liteservers
    mv config.json.liteservers config.json
}

ip2dec() {
    IFS='.' read -ra ADDR <<< "$PUBLIC_IP"
    DEC_IP=$(( (${ADDR[0]} << 24) + (${ADDR[1]} << 16) + (${ADDR[2]} << 8) + ${ADDR[3]} ))
}

replace_ip_port_config_json() {
    jq --arg dec_ip "$DEC_IP" --argjson validator_port "$VALIDATOR_PORT" --argjson lite_port "$LITE_PORT" '
    .addrs[0].ip = ($dec_ip | tonumber) |
    .addrs[0].port = $validator_port |
    .liteservers[0].port = $lite_port |
    .control[0].port = $validator_port' /var/ton-work/db/config.json > /var/ton-work/db/config_updated.json

    # Optionally, to overwrite the original file:
    mv /var/ton-work/db/config_updated.json /var/ton-work/db/config.json
}

replace_validator_config() {
    # @type at the root
    # jq '."@type"' input.json

    # out_port
    jq '.out_port' input.json

    # first addr's @type
    # jq '.addrs[0]."@type"' input.json

    # first addr's ip
    jq '.addrs[0].ip' input.json

    # first addr's port
    jq '.addrs[0].port' input.json

# # first addr's categories
# jq '.addrs[0].categories[]' input.json
}

replace_controlInterface() {
    # control's @type
    # jq '.control[0]."@type"' input.json

    # control's id
    jq '.control[0].id' input.json

    # control's port
    jq '.control[0].port' input.json
        server
}

replace_controlprocess() {
    # control's allowed @type
    # jq '.control[0].allowed[0]."@type"' input.json

    # control's allowed id
    jq '.control[0].allowed[0].id' input.json

    # control's allowed permissions
    # jq '.control[0].allowed[0].permissions' input.json
    client
}

replace_dht_key() {
    # jq '.adnl[0]."@type"' input.json
    jq '.adnl[0].id' input.json
    # jq '.adnl[0].category' input.json

    # jq '.dht[0]."@type"' input.json
    jq '.dht[0].id' input.json

    adnl
    dht
}

replace_fullnode_key() {

    # jq '.adnl[1]."@type"' input.json
    jq '.adnl[1].id' input.json
    # jq '.adnl[1].category' input.json

    jq '.fullnode' input.json

    adnl
    fullnode
}

replace_liteserver_key() {
    # liteserver's @type
    # jq '.liteservers[0]."@type"' input.json

    # liteserver's id
    jq '.liteservers[0].id' input.json

    # liteserver's port
    jq '.liteservers[0].port' input.json
}

env_variable

echo -e "------------------------------------------------------------"

echo -e "${COLOR_YELLOW}檢查 global.config.json${ENDC}"
if [ -f "/usr/bin/ton/global.config.json" ]; then
    echo -e "- 存在 global.config.json"
else
    echo -e "- 下載 global.config.json"
    get_global_config
fi

echo -e "------------------------------------------------------------"

set_archive_node_mode

echo -e "------------------------------------------------------------"

echo -e "${COLOR_YELLOW}檢查 config.json${ENDC}"
if [ -f "./config.json" ]; then
    echo -e "- 存在 config.json"
else
    echo -e "- 生成 config.json"
    generate_config_json
fi
# 生成 兩個 adnl key , 一個 for fullnode 一個 for dht
# "fullnode" : "3yR2qk2y76s06qC88Pw1tDTZuKymHD3pxJrz1pvX3Ao=",
# "dht" : : "TZuJr2CPBL6f+J9IOv8ehWSMoMBpSZEjn5hBxUPFWqM="
# 替換 SERVER_ID2 --> SERVER-ID engine.controlInterface
# 替換 CLIENT_ID2 --> CLIENT-ID engine.controlProcess

echo -e "------------------------------------------------------------"

echo -e "${COLOR_YELLOW}檢查 server key, server.pub key${ENDC}"

if [ -f "./server" ]; then
    echo -e "- 存在 server key, server.pub key"
else 
    echo -e "- 生成 server key, server.pub key"
    generate_server_key
    # replace_controlinterface
fi
# 寫入 server 到 /var/ton-work/db/keyring/



echo -e "------------------------------------------------------------"


echo -e "${COLOR_YELLOW}檢查 client key, client.pub key${ENDC}"

if [ -f "./client" ]; then 
    echo -e "- 存在 client key, client.pub key"
else
    echo -e "- 生成 client key, client.pub key"
    generate_client_key
    # replace_controlprocess
fi
# 寫入 client 到 /var/ton-work/db/keyring/

echo -e "------------------------------------------------------------"

echo -e "${COLOR_YELLOW}檢查 liteserver key, liteserver.pub key${ENDC}"

if [ -f "./liteserver" ]; then
    echo -e "- 存在 liteserver key, liteserver.pub key"
else 
    echo -e "- 生成 liteserver key, liteserver.pub key"
    generate_liteserver_key
    # replace_liteserver_key
fi
# 寫入 liteserver 到 /var/ton-work/db/keyring/



echo -e "------------------------------------------------------------"

echo -e "${COLOR_YELLOW}檢查 dht key, dht.pub key${ENDC}"

if [ -f "./dht" ]; then
    echo -e "- 存在 dht key, dht.pub key"
else 
    echo -e "- 生成 dht key, dht.pub key"
    generate_dht_key
    # replace_dht_key
fi
# 寫入 dht 到 /var/ton-work/db/keyring/

echo -e "------------------------------------------------------------"

echo -e "${COLOR_YELLOW}檢查 fullnode key, fullnode.pub key${ENDC}"

if [ -f "./fullnode" ]; then
    echo -e "- 存在 fullnode key, fullnode.pub key"
else 
    echo -e "- 生成 fullnode key, fullnode.pub key"
    generate_fullnode_key
    # replace_fullnode_key
fi
# 寫入 fullnode 到 /var/ton-work/db/keyring/


# 格式化
jq '.' config.json > temp.json && mv temp.json config.json

echo -e "------------------------------------------------------------"

echo -e "${COLOR_YELLOW}清除 log${ENDC}"
clean_log

echo -e "------------------------------------------------------------"

# ip 轉換為 10進位
ip2dec

# 刷新 config.json 裡面的 ip 和 port
replace_ip_port_config_json

display_node_info

exec validator-engine /var/ton-work/db/config.json --global-config /usr/bin/ton/global.config.json --db /var/ton-work/db --verbosity $VALIDATOR_VERBOSITY --threads $VALIDATOR_THREADS --state-ttl $VALIDATOR_STATE_TTL --archive-ttl $VALIDATOR_ARCHIVE_TTL --block-ttl $VALIDATOR_BLOCK_TTL







# gc's @type
# jq '.gc."@type"' input.json