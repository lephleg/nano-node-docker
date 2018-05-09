#!/bin/bash

# OUTPUT VARS
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
bold=`tput bold`
reset=`tput sgr0`

# FLAGS & ARGUMENTS
quiet='false'
displaySeed='false'
domain=''
email=''
while getopts 'sqd:e:' flag; do
  case "${flag}" in
    s) displaySeed='true' ;;
    d) domain="${OPTARG}" ;;
    e) email="${OPTARG}" ;;
    q) quiet='true' ;;
    *) exit 0 ;;
  esac
done

# SPIN UP THE APPROPRIATE STACK
[[ $quiet = 'false' ]] && echo "${yellow}Pulling images and spinning up containers...${reset}"

if [[ $domain ]]; then
    cp -rf docker-compose.letsencrypt.yml docker-compose.generated.yml

    sed -i -e "s/      - VIRTUAL_HOST=mydomain.com/      - VIRTUAL_HOST=$domain/g" docker-compose.generated.yml
    sed -i -e "s/      - LETSENCRYPT_HOST=mydomain.com/      - LETSENCRYPT_HOST=$domain/g" docker-compose.generated.yml
    sed -i -e "s/      - DEFAULT_HOST=mydomain.com/      - DEFAULT_HOST=$domain/g" docker-compose.generated.yml

    if [[ $email ]]; then
        sed -i -e "s/      - LETSENCRYPT_EMAIL=myemailaddress@mail.com/      - LETSENCRYPT_EMAIL=$email/g" docker-compose.generated.yml
    fi

    if [[ $quiet = 'false' ]]; then
        docker-compose -f docker-compose.generated.yml up -d
    else
        docker-compose -f docker-compose.generated.yml up -d 2>/dev/null
    fi
else
    if [[ $quiet = 'false' ]]; then
        docker-compose up -d
    else
        docker-compose up -d 2>/dev/null
    fi
fi

# CHECK NODE INITIALIZATION
[[ $quiet = 'false' ]] && printf "${yellow}Waiting for NANO node to fully initialize... "

isRpcLive="$(curl -s -d '{"action": "version"}' 127.0.0.1:7076 | grep "rpc_version")"
while [ ! -n "$isRpcLive" ];
do
    sleep 1s
    isRpcLive="$(curl -s -d '{"action": "version"}' 127.0.0.1:7076 | grep "rpc_version")"
done

[[ $quiet = 'false' ]] && printf "${green}done.${reset}\n"

# WALLET SETUP
existedWallet="$(docker exec -it nano-node /usr/bin/rai_node --wallet_list | grep 'Wallet ID' | awk '{ print $NF}')"

if [[ ! $existedWallet ]]; then
    [[ $quiet = 'false' ]] && printf "${yellow}No wallet found. Generating a new one... ${reset}"

    walletId=$(docker exec -it nano-node /usr/bin/rai_node --wallet_create | tr -d '\r')
    address=$(docker exec -it nano-node /usr/bin/rai_node --account_create --wallet=$walletId | awk '{ print $NF}')
    
    [[ $quiet = 'false' ]] && printf "${green}done.${reset}\n"
else
    [[ $quiet = 'false' ]] && echo "${yellow}Existing wallet found.${reset}"

    address="$(docker exec -it nano-node /usr/bin/rai_node --wallet_list | grep 'xrb_' | awk '{ print $NF}' | tr -d '\r')"
    walletId=$(echo $existedWallet | tr -d '\r')

fi

if [[ $quiet = 'false' && $displaySeed = 'true' ]]; then
    seed=$(docker exec -it nano-node /usr/bin/rai_node --wallet_decrypt_unsafe --wallet=$walletId | grep 'Seed' | awk '{ print $NF}')
fi

if [[ $quiet = 'false' ]]; then
    echo "${yellow} -------------------------------------------------------------------------------------- ${reset}"
    echo "${yellow} Node account address: ${green}$address${yellow} "
    if [[ $displaySeed = 'true' ]]; then
        echo "${yellow} Node wallet seed: ${red}${bold}$seed${reset}${yellow} "
    fi
    echo "${yellow} -------------------------------------------------------------------------------------- ${reset}"
fi

# UPDATE MONITOR CONFIGS
if [ ! -f ./nano-node-monitor/config.php ]; then
    [[ $quiet = 'false' ]] && echo "${yellow}No existing NANO Node Monitor config file found. Fetching a fresh copy...${reset}"
    if [[ $quiet = 'false' ]]; then
        docker-compose restart nano-node-monitor
    else
        docker-compose restart nano-node-monitor > /dev/null
    fi
fi

[[ $quiet = 'false' ]] && printf "${yellow}Configuring NANO Node Monitor... ${reset}"

sed -i -e "s/\/\/ \$nanoNodeRPCIP.*;/\$nanoNodeRPCIP/g" ./nano-node-monitor/config.php
sed -i -e "s/\$nanoNodeRPCIP.*/\$nanoNodeRPCIP = 'nano-node';/g" ./nano-node-monitor/config.php

sed -i -e "s/\/\/ \$nanoNodeAccount.*;/\$nanoNodeAccount/g" ./nano-node-monitor/config.php
sed -i -e "s/\$nanoNodeAccount.*/\$nanoNodeAccount = '$address';/g" ./nano-node-monitor/config.php

if [[ $domain ]]; then
    sed -i -e "s/\/\/ \$nanoNodeName.*;/\$nanoNodeName = '$domain';/g" ./nano-node-monitor/config.php
else 
    ipAddress=$(curl -s v4.ifconfig.co | awk '{ print $NF}' | tr -d '\r')
    sed -i -e "s/\/\/ \$nanoNodeName.*;/\$nanoNodeName = 'nano-node-docker-stack-$ipAddress';/g" ./nano-node-monitor/config.php
fi

sed -i -e "s/\/\/ \$welcomeMsg.*;/\$welcomeMsg = 'Welcome! This node was setup using <a href=\"https:\/\/github.com\/lephleg\/nano-node-monitor-docker-stack\" target=\"_blank\">NANO Node Monitor Docker stack<\/a>!';/g" ./nano-node-monitor/config.php
sed -i -e "s/\/\/ \$blockExplorer.*;/\$blockExplorer = 'meltingice';/g" ./nano-node-monitor/config.php

[[ $quiet = 'false' ]] && printf "${green}done.${reset}\n"

if [[ $quiet = 'false' ]]; then
    echo "${yellow} ------------------------------------------------------------------------------"
    echo "${green} ${bold}Congratulations! NANO Node Monitor Docker stack has been setup successfully!${reset}"
    echo "${yellow} ------------------------------------------------------------------------------ ${reset}"
    if [[ $domain ]]; then
        echo "${yellow}Open a browser and navigate to ${green}https://$domain${yellow} to check your monitor."
    else
        echo "${yellow}Open a browser and navigate to ${green}http://$ipAddress${yellow} to check your monitor."
    fi
    echo "${yellow}You can further configure and personalize your monitor by editing the config file located in ${green}nano-node-monitor/config.php${yellow}.${reset}"
fi