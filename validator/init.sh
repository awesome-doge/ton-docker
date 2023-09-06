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

# global config
wget -q https://ton-blockchain.github.io/global.config.json -O /usr/bin/ton/global.config.json
echo -e "\e[1;31m[!]\e[0m global config"
echo -e "\e[1;31m[!]\e[0m global config"

# Init local config with IP:PORT
if [ ! -z "$PUBLIC_IP" ]; then
    if [ -z "$CONSOLE_PORT" ]; then
        CONSOLE_PORT="43678"
    fi
    echo -e "\e[1;32m[+]\e[0m Using provided IP: $PUBLIC_IP:$CONSOLE_PORT"
    validator-engine -C /usr/bin/ton/global.config.json --db /var/ton-work/db --ip "$PUBLIC_IP:$CONSOLE_PORT"
else
    echo -e "\e[1;31m[!]\e[0m No IP:PORT provided, exiting"
    exit 1
fi

# Generating server certificate
if [ -f "./server" ]; then
    echo -e "\e[1;33m[=]\e[0m Found existing server certificate, skipping"
else 
    echo -e "\e[1;32m[+]\e[0m Generating and installing server certificate for remote control"
    read -r SERVER_ID1 SERVER_ID2 <<< $(generate-random-id -m keys -n server)
    echo "Server IDs: $SERVER_ID1 $SERVER_ID2"
    cp server /var/ton-work/db/keyring/$SERVER_ID1
fi

# Generating client certificate
if [ -f "./client" ]; then 
    echo -e "\e[1;33m[=]\e[0m Found existing client certificate, skipping"
else
    read -r CLIENT_ID1 CLIENT_ID2 <<< $(generate-random-id -m keys -n client)
    echo -e "\e[1;32m[+]\e[0m Generated client private certificate $CLIENT_ID1 $CLIENT_ID2"
    echo -e "\e[1;32m[+]\e[0m Generated client public certificate"
    # Adding client permissions
    sed -e "s/CONSOLE-PORT/\"$(printf "%q" $CONSOLE_PORT)\"/g" -e "s~SERVER-ID~\"$(printf "%q" $SERVER_ID2)\"~g" -e "s~CLIENT-ID~\"$(printf "%q" $CLIENT_ID2)\"~g" control.template > control.new
    sed -e "s~\"control\"\ \:\ \[~$(printf "%q" $(cat control.new))~g" config.json > config.json.new
    mv config.json.new config.json
fi

# Liteserver
if [ -z "$LITESERVER" ]; then
    echo -e "\e[1;33m[=]\e[0m Liteserver disabled"
else
    if [ -f "./liteserver" ]; then
        echo -e "\e[1;33m[=]\e[0m Found existing liteserver certificate, skipping"
    else 
        echo -e "\e[1;32m[+]\e[0m Generating and installing liteserver certificate for remote control"
        read -r LITESERVER_ID1 LITESERVER_ID2 <<< $(generate-random-id -m keys -n liteserver)
        echo "Liteserver IDs: $LITESERVER_ID1 $LITESERVER_ID2"
        cp liteserver /var/ton-work/db/keyring/$LITESERVER_ID1
        if [ -z "$LITE_PORT" ]; then
            LITE_PORT="43679"
        fi
        LITESERVERS=$(printf "%q" "\"liteservers\":[{\"id\":\"$LITESERVER_ID2\",\"port\":\"$LITE_PORT\"}")
        sed -e "s~\"liteservers\"\ \:\ \[~$LITESERVERS~g" config.json > config.json.liteservers
        mv config.json.liteservers config.json
    fi
fi

echo -e "\e[1;32m[+]\e[0m Running validator-engine"


exec validator-engine /var/ton-work/db/config.json --global-config /usr/bin/ton/global.config.json  --db /var/ton-work/db 

# exec validator-engine /var/ton-work/db/config.json --global-config /usr/bin/ton/global.config.json  --db /var/ton-work/db --verbosity $VALIDATOR_VERBOSITY --threads $VALIDATOR_THREADS --state-ttl $VALIDATOR_STATE_TTL --archive-ttl $VALIDATOR_ARCHIVE_TTL --block-ttl $VALIDATOR_BLOCK_TTL
