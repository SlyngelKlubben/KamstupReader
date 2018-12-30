IP=$1
if [[ $IP == "" ]] ; then
    IP="192.168.0.200"
fi
echo "IP=$IP"
curl  -H "Content-Type: application/json" -X GET http://${IP}:3000/hus/public/tyv | \
 jq -r '(map(keys)  | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv'
