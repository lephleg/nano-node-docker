#!/bin/bash

# VERSION
version='v4.1 - BETA Network'

# OUTPUT VARS
red=`tput setaf 1`
green=`tput setaf 2`
yellow=`tput setaf 3`
bold=`tput bold`
reset=`tput sgr0`

# FLAGS & ARGUMENTS
quiet='false'
displaySeed='false'
fastSync='false'
domain=''
email=''
tag=''
while getopts 'sqfd:e:t:' flag; do
  case "${flag}" in
    s) displaySeed='true' ;;
    d) domain="${OPTARG}" ;;
    e) email="${OPTARG}" ;;
    q) quiet='true' ;;
    f) fastSync='true' ;;
    t) tag="${OPTARG}" ;;
    *) exit 1 ;;
  esac
done

echo $@ > settings

# PRINT INSTALLER DETAILS
[[ $quiet = 'false' ]] && echo "${green} ------------------------------------${reset}"
[[ $quiet = 'false' ]] && echo "${green}${bold} NANO Node Docker ${version}${reset}"
[[ $quiet = 'false' ]] && echo "${green} ------------------------------------${reset}"
[[ $quiet = 'false' ]] && echo ""

# VERIFY TOOLS INSTALLATIONS
docker -v &> /dev/null
if [ $? -ne 0 ]; then
    echo "${red}Docker is not installed. Please follow the install instructions for your system at https://docs.docker.com/install/.${reset}";
    exit 2
fi

docker-compose --version &> /dev/null
if [ $? -ne 0 ]; then
    echo "${red}Docker Compose is not installed. Please follow the install instructions for your system at https://docs.docker.com/compose/install/.${reset}"
    exit 2
fi

if [[ $fastSync = 'true' ]]; then
    wget --version &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${red}wget is not installed and is required for fast-syncing.${reset}";
        exit 2
    fi

    7z &> /dev/null
    if [ $? -ne 0 ]; then
        echo "${red}7-Zip is not installed and is required for fast-syncing.${reset}";
        exit 2
    fi
fi

# FAST-SYNCING
if [[ $fastSync = 'true' ]]; then
    echo "${red}Fast-syncing is not available for the BETA network.${reset}";
    exit 2
fi

# DETERMINE IF THIS IS AN INITIAL INSTALL
[[ $quiet = 'false' ]] && echo "=> ${yellow}Checking initial status...${reset}"
[[ $quiet = 'false' ]] && echo ""

if [ -d "./nano-beta-node" ]; then
    # check if mounted directory follows the new /root structure
    if [ ! -d "./nano-beta-node/RaiBlocksBeta" ]; then
        if [ ! -d "./nano-beta-node/NanoBeta" ]; then
            [[ $quiet = 'false' ]] && printf "${reset}Unsupported directory structure detected. Migrating files... "
            mkdir ./nano-beta-node/RaiBlocksBeta
            # move everything into subdirectory and suppress the error about itself
            mv ./nano-beta-node/* ./nano-beta-node/RaiBlocksBeta/ &> /dev/null
            [[ $quiet = 'false' ]] && printf "${green}done.\n${reset}"
            [[ $quiet = 'false' ]] && echo ""
        fi
    fi
fi

# SPIN UP THE APPROPRIATE STACK
[[ $quiet = 'false' ]] && echo "=> ${yellow}Pulling images and spinning up containers...${reset}"
[[ $quiet = 'false' ]] && echo ""

docker network create nano-beta-node-network &> /dev/null

if [[ $domain ]]; then

    if [[ $tag ]]; then
        sed -i -e "s/    image: nanocurrency\/nano-beta:.*/    image: nanocurrency\/nano-beta:$tag/g" docker-compose.letsencrypt.yml
    fi

    sed -i -e "s/      - VIRTUAL_HOST=.*/      - VIRTUAL_HOST=$domain/g" docker-compose.letsencrypt.yml
    sed -i -e "s/      - LETSENCRYPT_HOST=.*/      - LETSENCRYPT_HOST=$domain/g" docker-compose.letsencrypt.yml
    sed -i -e "s/      - DEFAULT_HOST=.*/      - DEFAULT_HOST=$domain/g" docker-compose.letsencrypt.yml

    if [[ $email ]]; then
        sed -i -e "s/      - LETSENCRYPT_EMAIL=.*/      - LETSENCRYPT_EMAIL=$email/g" docker-compose.letsencrypt.yml
    fi

    if [[ $quiet = 'false' ]]; then
        docker-compose -f docker-compose.letsencrypt.yml up -d
    else
        docker-compose -f docker-compose.letsencrypt.yml up -d &> /dev/null
    fi

else

    if [[ $tag ]]; then
        sed -i -e "s/    image: nanocurrency\/nano-beta:.*/    image: nanocurrency\/nano-beta:$tag/g" docker-compose.yml
    fi

    if [[ $quiet = 'false' ]]; then
        docker-compose up -d
    else
        docker-compose up -d &> /dev/null
    fi

fi

if [ $? -ne 0 ]; then
    echo "${red}It seems errors were encountered while spinning up the containers. Scroll up for more info on how to fix them.${reset}"
    exit 2
fi

# CHECK NODE INITIALIZATION
[[ $quiet = 'false' ]] && echo ""
[[ $quiet = 'false' ]] && printf "=> ${yellow}Waiting for NANO node to fully initialize... "

isRpcLive="$(curl -s -d '{"action": "version"}' [::1]:55000 | grep "rpc_version")"
while [ ! -n "$isRpcLive" ];
do
    sleep 1s
    isRpcLive="$(curl -s -d '{"action": "version"}' [::1]:55000 | grep "rpc_version")"
done

[[ $quiet = 'false' ]] && printf "${green}done.${reset}\n\n"

# DETERMINE NODE VERSION
nodeExec="docker exec -it nano-beta-node /usr/bin/nano_node"

# SET BASH ALIASES FOR NODE CLI
if [ -f ~/.bash_aliases ]; then
    alias=$(cat ~/.bash_aliases | grep 'rai');
    if [[ ! $alias ]]; then
        echo "alias rai='${nodeExec}'" >> ~/.bash_aliases;
        source ~/.bashrc;
    fi
else
    echo "alias rai='${nodeExec}'" >> ~/.bash_aliases;
    source ~/.bashrc;
fi

# WALLET SETUP
existedWallet="$(${nodeExec} --wallet_list | grep 'Wallet ID' | awk '{ print $NF}')"

if [[ ! $existedWallet ]]; then
    [[ $quiet = 'false' ]] && printf "=> ${yellow}No wallet found. Generating a new one... ${reset}"

    walletId=$(${nodeExec} --wallet_create | tr -d '\r')
    address="$(${nodeExec} --account_create --wallet=$walletId | awk '{ print $NF}')"
    
    [[ $quiet = 'false' ]] && printf "${green}done.${reset}\n\n"
else
    [[ $quiet = 'false' ]] && echo "=> ${yellow}Existing wallet found.${reset}"
    [[ $quiet = 'false' ]] && echo ''

    address="$(${nodeExec} --wallet_list | grep 'nano_' | awk '{ print $NF}' | tr -d '\r')"
    walletId=$(echo $existedWallet | tr -d '\r')
fi

if [[ $quiet = 'false' && $displaySeed = 'true' ]]; then
    seed=$(${nodeExec} --wallet_decrypt_unsafe --wallet=$walletId | grep 'Seed' | awk '{ print $NF}')
fi

# UPDATE MONITOR CONFIGS
if [ ! -f ./nano-node-monitor/config.php ]; then
    [[ $quiet = 'false' ]] && echo "=> ${yellow}No existing NANO Node Monitor config file found. Fetching a fresh copy...${reset}"
    if [[ $quiet = 'false' ]]; then
        docker-compose restart nano-node-monitor
    else
        docker-compose restart nano-node-monitor > /dev/null
    fi
fi

[[ $quiet = 'false' ]] && printf "=> ${yellow}Configuring NANO Node Monitor... ${reset}"

sed -i -e "s/\/\/ \$currency.*;/\$currency/g" ./nano-node-monitor/config.php
sed -i -e "s/\$currency.*/\$currency = 'nano-beta';/g" ./nano-node-monitor/config.php

sed -i -e "s/\/\/ \$nanoNodeRPCIP.*;/\$nanoNodeRPCIP/g" ./nano-node-monitor/config.php
sed -i -e "s/\$nanoNodeRPCIP.*/\$nanoNodeRPCIP = 'nano-beta-node';/g" ./nano-node-monitor/config.php

sed -i -e "s/\/\/ \$nanoNodeRPCPort.*;/\$nanoNodeRPCPort/g" ./nano-node-monitor/config.php
sed -i -e "s/\$nanoNodeRPCPort.*/\$nanoNodeRPCPort = '55000';/g" ./nano-node-monitor/config.php

sed -i -e "s/\/\/ \$nanoNodeAccount.*;/\$nanoNodeAccount/g" ./nano-node-monitor/config.php
sed -i -e "s/\$nanoNodeAccount.*/\$nanoNodeAccount = '$address';/g" ./nano-node-monitor/config.php

if [[ $domain ]]; then
    sed -i -e "s/\/\/ \$nanoNodeName.*;/\$nanoNodeName = '$domain';/g" ./nano-node-monitor/config.php
else 
    ipAddress=$(curl -s v4.ifconfig.co | awk '{ print $NF}' | tr -d '\r')

    # in case of an ipv6 address, add square brackets
    if [[ $ipAddress =~ .*:.* ]]; then
        ipAddress="[$ipAddress]"
    fi

    sed -i -e "s/\/\/ \$nanoNodeName.*;/\$nanoNodeName = 'nano-beta-node-docker-$ipAddress';/g" ./nano-node-monitor/config.php
fi

sed -i -e "s/\/\/ \$welcomeMsg.*;/\$welcomeMsg = 'Welcome! This <strong>BETA<\/strong> node was setup using <a href=\"https:\/\/github.com\/lephleg\/nano-node-docker\" target=\"_blank\">NANO Node Docker<\/a>!';/g" ./nano-node-monitor/config.php
sed -i -e "s/\/\/ \$blockExplorer.*;/\$blockExplorer = 'meltingice-beta';/g" ./nano-node-monitor/config.php

# remove any carriage returns may have been included by sed replacements
sed -i -e 's/\r//g' ./nano-node-monitor/config.php

[[ $quiet = 'false' ]] && printf "${green}done.${reset}\n\n"

if [[ $quiet = 'false' ]]; then
    echo "${yellow} |======================================================================================| ${reset}"
    echo "${green} ${bold}|Congratulations! NANO Node Docker stack has been setup successfully!                  |${reset}"
    echo "${yellow} |======================================================================================| ${reset}"
    echo "${yellow} |Node account address: ${green}$address${yellow}|"
    if [[ $displaySeed = 'true' ]]; then
        echo "${yellow} |Node wallet seed: ${red}${bold}$seed${reset}${yellow}    |"
    fi
    echo "${yellow} |======================================================================================| ${reset}"

    echo ""

    if [[ $domain ]]; then
        echo "${yellow} Open a browser and navigate to ${green}https://$domain${yellow} to check your monitor."
    else
        echo "${yellow} Open a browser and navigate to ${green}http://$ipAddress${yellow} to check your monitor."
    fi
    echo "${yellow} You can further configure and personalize your monitor by editing the config file located in ${green}nano-node-monitor/config.php${yellow}.${reset}"

    echo ""

fi