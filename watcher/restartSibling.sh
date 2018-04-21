#!/bin/sh

# adapted from https://github.com/jamischarles/test-docker-sibling-restart

# 1st param is json
# 2nd param is key to extract
function getjsonval {
  temp=`echo $1 | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $2 | cut -d":" -f2| sed -e 's/^ *//g' -e 's/ *$//g'`
  echo ${temp##*|}
}

# From inside the container:
# - call the parent docker process via the docker domain socket
# - use the docker API to find the ID of the docker container we want
# - start a 20 second loop
# - call the block_count node RPC
# - check response for Error string
#   use the docker API to restart node container

APP_NAME=$watchname

# call the parent docker process via the docker unix socket and use the API to find any running container with
# the following label: com.docker.compose.service=little_brother (you can see these when you inspect that container)
json=$(curl --silent --unix-socket /var/run/docker.sock -gG -X GET http://v1.30/containers/json \
  --data-urlencode 'filters={"label": {"com.docker.compose.service='$APP_NAME'": true}}')

# echo "json: $json"

# extract the container ID from json response
containerID=$(getjsonval "$json" "Id")

# echo $containerID;

# initiate loop
while true; 

do

  # RPC request to node
  nodeResponse=$(curl --silent -g -d '{ "action": "block_count" }' $watchname':'$watchport)

  # RPC response
  # echo "nodeResponse: $nodeResponse"

  # process RPC response
  case "$nodeResponse" in 
    *Error*)
      echo "Restarting containerID: $containerID"          
      curl --silent --unix-socket /var/run/docker.sock -X POST http://v1.30/containers/${containerID}/restart?t=5
    ;;
  esac

  sleep $watchInterval; 

done