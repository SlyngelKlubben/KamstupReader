## Install Prest RESTfull frontend to Postgres
## https://github.com/prest/prest


## Check if Prest is alredy there
if [[ -e /opt/Prest/prest-linux-arm-7 ]] ; then
    echo "PREST already installed. Exiting"
    exit
else 
## Download Prest
    wget https://github.com/prest/prest/releases/download/v0.3.0/prest-linux-arm-7

    ## Copy to system location
    sudo mkdir /opt/Prest
    sudo cp prest-linux-arm-7 /opt/Prest
fi

## Check if rc.local starts Prest
if grep -q prest-linux-arm-7 rc.local ; then
    echo "rc.local starts prest"
else
    echo "Needs to update rc.local"
fi




## update rc.local
