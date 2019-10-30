IP=$1
DB=$2
if [[ $IP == "" ]] ; then
    IP="192.168.0.200"
fi
if [[ $DB == "" ]] ; then
    DB="tyv"
fi
echo "IP=$IP"
echo "DB=$DB" ## table actually
curl  -H "Content-Type: application/json" -X GET http://${IP}:3000/hus/public/${DB} | \
 jq -r '(map(keys)  | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv'
