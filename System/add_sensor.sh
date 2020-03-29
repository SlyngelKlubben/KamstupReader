## Add a sensor
## add_sensor.sh MAC NAME IP X Y Z
MAC=$1
NAME=$2
IP=$3
X=$4
Y=$5
Z=$6

## Check format of first parameter
MAC=$(echo $MAC | sed "s/\(.*\)/\U\1/")
case $MAC
in 
  [0-9A-F][0-9A-F]:[0-9A-Z][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F]:[0-9A-F][0-9A-F])
    echo "Valid MAC: $MAC"
  ;;
  *) echo "First parameter must be MAC" ; exit
  ;;
esac

## Check format of 3rd parameter
if [[ $IP =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "IP: $IP"
else
    echo "3rd parameter must be IP. Got: $IP"
    exit
fi


if [[ -n "$6" ]] ; then
    STMT="{\"mac\":\"$MAC\",\"name\":\"$NAME\",\"location\":\"SRID=25832;POINTZ($X $Y $Z)\"}"
else
    STMT="{\"mac\":\"$MAC\",\"name\":\"$NAME\"}"
fi
echo $STMT

curl -d "$STMT" -H "Content-Type: application/json" -X POST ${IP}:3000/hus/public/sensor_location

##STMT='{"mac":"84:F3:EB:3B:7C:EB","name":"spisestue"}'
## curl -d '{"content":"DetVirker"}' -H "Content-Type: application/json" -X POST http://192.168.0.200:3000/hus/public/tyv
