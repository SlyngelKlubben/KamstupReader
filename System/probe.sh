curl  -H "Content-Type: application/json" -X GET http://192.168.0.200:3000/hus/public/tyv | \
 jq -r '(map(keys)  | add | unique) as $cols | map(. as $row | $cols | map($row[.])) as $rows | $cols, $rows[] | @csv'
