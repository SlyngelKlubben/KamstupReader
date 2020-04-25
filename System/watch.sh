#!/bin/bash
## Usage: watch.sh PATH/TO/config.yml


CONF="$1"

if [[ $CONF = "" ]] ; then
    CONF="config.yml"
    echo "No config path given. Using "
else
    echo "Loading config from "
fi

echo $CONF

parse_yaml() { ## Thank you https://gist.github.com/pkuczynski/8665367
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\)\($w\)$s:$s\"\(.*\)\"$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

watch() {
    ## call as watch $config_db_host dead
    ## to push when dead
    ## call as watch $config_db_host
    ## to test
    local ip=$1
    local push=$2
    local state="dunno"
    
    local stmt="http://${ip}:3000/hus/${config_db_schema}/${config_db_envitable}?id=1"
    if [[ `curl  -H "Content-Type: application/json" -X GET "${stmt}"` ]] ; then
	state="alive"
    else
	state="dead"
    fi
    local myip=`hostname -I | cut -f 1 -d " "`
    local msg="${myip} says: Øv også! ${ip} is ${state}"
    if [[ $push = $state ]] ; then
	echo "pushing $msg"
	curl -d "token=${config_pushover_token}&user=${config_pushover_user}&message=$msg" https://api.pushover.net/1/messages.json
    fi
    echo $msg
}

eval $(parse_yaml $CONF "config_")

watch $config_db_host dead 2>/dev/null
watch $config_watchdog_host dead 2>/dev/null


