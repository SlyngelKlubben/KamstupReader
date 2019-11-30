## Install Prest RESTfull frontend to Postgres
## https://github.com/prest/prest


## Check if Prest is alredy there
if [[ -e /opt/Prest/prest-linux-arm-7 ]] ; then
    echo "PREST already installed."
else 
## Download Prest
    wget https://github.com/prest/prest/releases/download/v0.3.0/prest-linux-arm-7

    ## Copy to system location
    sudo mkdir /opt/Prest
    sudo cp prest-linux-arm-7 /opt/Prest
    sudo cp prest.toml /opt/Prest/
fi

## Check if rc.local starts Prest
if grep -q "prest-linux-arm-7" /etc/rc.local
then
    echo "rc.local starts prest"
else
    ## update rc.local
    echo "Updating rc.local"
    sudo sed -i '/^exit 0/i ## Run pRest server\ncd /opt/Prest/ && ./prest-linux-arm-7 > /opt/Prest/prest.log &\n\n' /etc/rc.local
fi

