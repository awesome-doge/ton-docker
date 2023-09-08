#!/usr/bin/env bash

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


display_validator_info() {
    local COLOR_GREEN='\033[32m'
    local COLOR_YELLOW='\033[33m'
    local ENDC='\033[0m'

    echo -e "------------------------------------------------------------"
    echo -e "VALIDATOR ENGINE START"
    echo -e "IP                    ${COLOR_GREEN}$PUBLIC_IP:$VALIDATOR_PORT${ENDC}"
    echo -e "NETWORK               ${COLOR_GREEN}$NETWORK${ENDC}"
    echo -e "NODE_MODE             ${COLOR_GREEN}$NODE_MODE${ENDC}"
    echo -e "VALIDATOR_STATE_TTL   ${COLOR_GREEN}$VALIDATOR_STATE_TTL${ENDC}"
    echo -e "VALIDATOR_ARCHIVE_TTL ${COLOR_GREEN}$VALIDATOR_ARCHIVE_TTL${ENDC}"
    echo -e "VALIDATOR_BLOCK_TTL   ${COLOR_GREEN}$VALIDATOR_BLOCK_TTL${ENDC}"
    echo -e "------------------------------------------------------------"
    echo -e "${COLOR_YELLOW}/${ENDC}"
    ls
    echo -e "------------------------------------------------------------"
    echo -e "${COLOR_YELLOW}/var/ton-work/db/${ENDC}"
    ls /var/ton-work/db/
    echo -e "------------------------------------------------------------"
    echo -e "${COLOR_YELLOW}/var/ton-work/db/keyring/${ENDC}"
    ls /var/ton-work/db/keyring/
    echo -e "------------------------------------------------------------"
    echo -e "${COLOR_YELLOW}/var/ton-work/db/config.json${ENDC}"
    cat config.json
    echo -e "------------------------------------------------------------"
}

clean_log() {
    echo -e "------------------------------------------------------------"
    echo -e "clean_log"
    find /var/ton-work/db -name 'LOG.old*' -exec rm {} +
    rm -r /var/ton-work/db/files/packages/temp.archive.*
    rm -r /var/ton-work/log*
    echo -e "------------------------------------------------------------"
}

# Color definitions
COLOR_GREEN='\033[92m'
COLOR_RED='\033[91m'
COLOR_YELLOW='\033[93m'
ENDC='\033[0m'

# Check the value of MAINNET
echo -e "${COLOR_YELLOW}Checking MAINNET value...${ENDC}"
if [[ "$MAINNET" -eq 0 ]]; then
    NETWORK="TESTNET"
    echo -e "${COLOR_GREEN}Selected network: $NETWORK${ENDC}"
    wget -q https://ton-blockchain.github.io/testnet-global.config.json -O /usr/bin/ton/global.config.json
elif [[ "$MAINNET" -eq 1 ]]; then
    NETWORK="MAINNET"
    echo -e "${COLOR_GREEN}Selected network: $NETWORK${ENDC}"
    wget -q https://ton-blockchain.github.io/global.config.json -O /usr/bin/ton/global.config.json
else
    echo -e "${COLOR_RED}Invalid value for MAINNET.${ENDC}"
    exit 1
fi

echo -e "${COLOR_YELLOW}------------------------------------------------------------${ENDC}"

# Check the value of ARCHIVE_NODE
if [[ "$ARCHIVE_NODE" -eq 0 ]]; then
    NODE_MODE="FULL NODE MODE"
    VALIDATOR_STATE_TTL=25200
    VALIDATOR_ARCHIVE_TTL=25200
    VALIDATOR_BLOCK_TTL=25200
elif [[ "$ARCHIVE_NODE" -eq 1 ]]; then
    NODE_MODE="ARCHIVE NODE MODE"
    VALIDATOR_STATE_TTL=315360000
    VALIDATOR_ARCHIVE_TTL=315360000
    VALIDATOR_BLOCK_TTL=315360000
else
    echo "Invalid value for ARCHIVE_NODE."
    exit 1
fi

# Init local config with IP:PORT
echo -e "${COLOR_YELLOW}Initializing local configuration...${ENDC}"
if [ ! -z "$PUBLIC_IP" ]; then
    if [ -z "$VALIDATOR_PORT" ]; then
        VALIDATOR_PORT="43678"
    fi
    display_validator_info
    clean_log
    echo -e "Using provided IP: ${COLOR_GREEN}$PUBLIC_IP:$VALIDATOR_PORT${ENDC}"
    validator-engine -C /usr/bin/ton/global.config.json --db /var/ton-work/db --ip "$PUBLIC_IP:$VALIDATOR_PORT" --verbosity $VALIDATOR_VERBOSITY --threads $VALIDATOR_THREADS --state-ttl $VALIDATOR_STATE_TTL --archive-ttl $VALIDATOR_ARCHIVE_TTL --block-ttl $VALIDATOR_BLOCK_TTL
else
    echo -e "${COLOR_RED}No IP:PORT provided, exiting${ENDC}"
    exit 1
fi

echo -e "------------------------------------------------------------"

# Generating Server Certificate /var/ton-work/db/keyring/
if [ -f "./server" ]; then
    echo -e "${COLOR_YELLOW} Found existing server certificate, skipping ${ENDC}"
else 
    echo -e "${COLOR_YELLOW}Generating and installing Server certificate for remote control...${ENDC}"
    # 生成一組 SERVER_ID1 SERVER_ID2
    echo -e "${COLOR_YELLOW}Generating Server certificate ...${ENDC}"
    read -r SERVER_ID1 SERVER_ID2 <<< $(generate-random-id -m keys -n server)
    echo -e "Server IDs:"
    echo -e "    ${COLOR_GREEN}$SERVER_ID1${ENDC}"
    echo -e "    ${COLOR_GREEN}$SERVER_ID2${ENDC}"
    echo -e "${COLOR_YELLOW}Installing Server certificate for remote control...(/var/ton-work/db/keyring/)${ENDC}"
    cp server /var/ton-work/db/keyring/$SERVER_ID1
fi

echo -e "------------------------------------------------------------"

# Generating Client Certificate
echo -e "${COLOR_YELLOW}Generating Client Certificate.....${ENDC}"
if [ -f "./client" ]; then 
    echo -e "${COLOR_YELLOW} Found existing client certificate, skipping ${ENDC}"
else
    # 生成一組 CLIENT_ID1 CLIENT_ID2
    read -r CLIENT_ID1 CLIENT_ID2 <<< $(generate-random-id -m keys -n client)
    if [ $? -ne 0 ]; then
        echo -e "${COLOR_RED}Error generating client IDs.${ENDC}"
        exit 1
    else
        echo -e "Client IDs:"
        echo -e "    ${COLOR_GREEN}$CLIENT_ID1${ENDC}"
        echo -e "    ${COLOR_GREEN}$CLIENT_ID2${ENDC}"
    fi

    echo -e "${COLOR_YELLOW}Generating "config.json"...${ENDC}"

    # echo -e "${COLOR_YELLOW}Generated client public certificate${ENDC} ${COLOR_GREEN}config.json${COLOR_GREEN}"
    
    # 修改 control.template 文件
    # 替換 VALIDATOR_PORT --> CONSOLE-PORT
    # 替換 SERVER_ID2 --> SERVER-ID 
    # 替換 CLIENT_ID2 --> CLIENT-ID
    # 生成的結果 control.template --> control.new
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
fi


echo -e "------------------------------------------------------------"

# Lite Server 寫入 config.json
if [ -z "$LITESERVER" ]; then
    echo -e "${COLOR_YELLOW} Liteserver disabled ${ENDC}"
else
    if [ -f "./liteserver" ]; then
        echo -e "${COLOR_YELLOW}Found existing Liteserver certificate, skipping ${ENDC}"
    else 
        echo -e "${COLOR_YELLOW}Generating and installing liteserver certificate for remote control ${ENDC}"
        read -r LITESERVER_ID1 LITESERVER_ID2 <<< $(generate-random-id -m keys -n liteserver)
        if [ $? -ne 0 ]; then
            echo -e "${COLOR_RED}Error generate-random-id -m keys -n liteserver${ENDC}"
            exit 1
        else
            echo -e "Liteserver IDs:"
            echo -e "    ${COLOR_GREEN}$LITESERVER_ID1${ENDC}"
            echo -e "    ${COLOR_GREEN}$LITESERVER_ID2${ENDC}"
        fi

        # 將 LITESERVER_ID1 複製到 /var/ton-work/db/keyring/
        cp liteserver /var/ton-work/db/keyring/$LITESERVER_ID1
        if [ -z "$LITE_PORT" ]; then
            LITE_PORT="43679"
        fi
        # 替換 LITESERVER_ID2 --> liteservers
        LITESERVERS=$(printf "%q" "\"liteservers\":[{\"id\":\"$LITESERVER_ID2\",\"port\":\"$LITE_PORT\"}")
        sed -e "s~\"liteservers\"\ \:\ \[~$LITESERVERS~g" config.json > config.json.liteservers
        mv config.json.liteservers config.json
        
        # 格式化
        jq '.' config.json > temp.json && mv temp.json config.json

    fi
fi



display_validator_info

exec validator-engine /var/ton-work/db/config.json --global-config /usr/bin/ton/global.config.json --db /var/ton-work/db --verbosity $VALIDATOR_VERBOSITY --threads $VALIDATOR_THREADS --state-ttl $VALIDATOR_STATE_TTL --archive-ttl $VALIDATOR_ARCHIVE_TTL --block-ttl $VALIDATOR_BLOCK_TTL