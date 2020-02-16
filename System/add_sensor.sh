## Add a sensor
## add_sensor.sh MAC NAME IP X Y Z
MAC=$1
NAME=$2
IP=$3
X=$4
Y=$5
Z=$6

STMT="{\"mac\":\"$MAC\",\"name\":\"$NAME\",\"location\":\"SRID=25832;POINTZ($X $Y $Z)\"}"
echo $STMT

curl -d "$STMT" -H "Content-Type: application/json" -X POST ${IP}:3000/hus/public/sensor_location

##STMT='{"mac":"84:F3:EB:3B:7C:EB","name":"spisestue"}'
## curl -d '{"content":"DetVirker"}' -H "Content-Type: application/json" -X POST http://192.168.0.200:3000/hus/public/tyv
